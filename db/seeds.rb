require 'csv'
require 'fileutils'
require 'tmpdir'

class GnafImporter
  def initialize(data_path)
    @data_path = data_path
    @imported_counts = {}
  end

  def import!
    unless Dir.exist?(@data_path)
      puts "❌ Data directory not found: #{@data_path}"
      return false
    end

    puts "🚀 Starting GNAF data import from: #{@data_path}"
    
    # Optimize PostgreSQL for large imports (session-level settings only)
    ActiveRecord::Base.connection.execute("SET synchronous_commit = OFF")
    ActiveRecord::Base.connection.execute("SET maintenance_work_mem = '256MB'")
    ActiveRecord::Base.connection.execute("SET work_mem = '64MB'")
    
    import_from_directory(@data_path)

    print_summary
    true
  end

  private

  def import_from_directory(base_dir)
    import_states_from_dir(base_dir)
    import_street_types_from_dir(base_dir)
    import_localities_from_dir(base_dir)
    import_street_localities_from_dir(base_dir)
    import_geocodes_from_dir(base_dir)
    import_addresses_from_dir(base_dir)
    update_locality_postcodes_from_addresses
  end

  def import_states_from_dir(base_dir)
    puts "📍 Importing states..."
    
    state_files = Dir.glob("#{base_dir}/**/*_STATE_psv.psv")
    
    state_files.each do |file_path|
      process_psv_file_direct(file_path) do |row|
        State.find_or_create_by(state_pid: row['STATE_PID']) do |state|
          state.state_name = row['STATE_NAME']
          state.state_abbreviation = row['STATE_ABBREVIATION']
          state.date_created = parse_date(row['DATE_CREATED'])
          state.date_retired = parse_date(row['DATE_RETIRED'])
        end
      end
    end
    
    @imported_counts[:states] = State.count
    puts "✅ Imported #{@imported_counts[:states]} states"
  end

  def import_street_types_from_dir(base_dir)
    puts "🛣️  Importing street types..."
    
    street_type_files = Dir.glob("#{base_dir}/**/Authority_Code_STREET_TYPE_AUT_psv.psv")
    
    street_type_files.each do |file_path|
      process_psv_file_direct(file_path) do |row|
        StreetType.find_or_create_by(street_type_code: row['CODE']) do |street_type|
          street_type.street_type_name = row['NAME']
          street_type.street_type_description = row['DESCRIPTION']
        end
      end
    end
    
    @imported_counts[:street_types] = StreetType.count
    puts "✅ Imported #{@imported_counts[:street_types]} street types"
  end

  def import_localities_from_dir(base_dir)
    puts "🏘️  Importing localities..."
    
    locality_files = Dir.glob("#{base_dir}/**/*_LOCALITY_psv.psv").reject { |f| f.include?('STREET_LOCALITY') }
    puts "  Found #{locality_files.size} locality files"
    
    locality_files.each do |file_path|
      puts "  Processing #{File.basename(file_path)}..."
      processed = 0
      
      process_psv_file_direct(file_path) do |row|
        state = State.find_by(state_pid: row['STATE_PID'])
        next unless state
        
        Locality.find_or_create_by(locality_pid: row['LOCALITY_PID']) do |locality|
          locality.locality_name = row['LOCALITY_NAME']
          locality.locality_class_code = row['LOCALITY_CLASS_CODE']
          locality.locality_class_name = nil # Not available in this file
          locality.state = state
          locality.postcode = row['PRIMARY_POSTCODE'].present? ? row['PRIMARY_POSTCODE'] : nil
          locality.latitude = nil # Not in locality file
          locality.longitude = nil # Not in locality file
          locality.date_created = parse_date(row['DATE_CREATED'])
          locality.date_retired = parse_date(row['DATE_RETIRED'])
        end
        
        processed += 1
        if processed % 1000 == 0
          print "#{processed/1000}k "
          STDOUT.flush
        end
      end
      
      puts "✅ #{processed} localities"
    end
    
    @imported_counts[:localities] = Locality.count
    puts "✅ Imported #{@imported_counts[:localities]} localities"
  end

  def import_street_localities_from_dir(base_dir)
    puts "🛣️  Importing street localities..."
    
    street_locality_files = Dir.glob("#{base_dir}/**/*_STREET_LOCALITY_psv.psv")
    puts "  Found #{street_locality_files.size} street locality files"
    @street_localities = {}
    
    street_locality_files.each do |file_path|
      puts "  Processing #{File.basename(file_path)}..."
      processed = 0
      
      process_psv_file_direct(file_path) do |row|
        @street_localities[row['STREET_LOCALITY_PID']] = {
          street_name: row['STREET_NAME'],
          street_type_code: row['STREET_TYPE_CODE'],
          street_class_code: row['STREET_CLASS_CODE']
        }
        
        processed += 1
        if processed % 5000 == 0
          print "#{processed/1000}k "
          STDOUT.flush
        end
      end
      
      puts "✅ #{processed} street localities"
    end
    
    puts "✅ Loaded #{@street_localities.size} street localities"
  end

  def import_geocodes_from_dir(base_dir)
    puts "🌍 Importing geocodes..."
    @geocodes = {}
    
    geocode_files = Dir.glob("#{base_dir}/**/*_ADDRESS_DEFAULT_GEOCODE_psv.psv")
    
    geocode_files.each do |file_path|
      puts "Processing #{File.basename(file_path)}..."
      
      process_psv_file_direct(file_path) do |row|
        @geocodes[row['ADDRESS_DETAIL_PID']] = {
          longitude: parse_decimal(row['LONGITUDE']),
          latitude: parse_decimal(row['LATITUDE']),
          geocode_type_code: row['GEOCODE_TYPE_CODE']
        }
      end
    end
    
    puts "✅ Loaded #{@geocodes.size} geocodes"
  end

  def import_addresses_from_dir(base_dir)
    puts "🏠 Importing addresses..."
    
    # Preload lookups for performance
    puts "Loading locality and street type lookups..."
    locality_lookup = Locality.pluck(:locality_pid, :id).to_h
    street_type_lookup = StreetType.pluck(:street_type_code, :id).to_h
    
    address_files = Dir.glob("#{base_dir}/**/*_ADDRESS_DETAIL_psv.psv")
    
    address_files.each do |file_path|
      file_name = File.basename(file_path)
      puts "Processing #{file_name}..."
      puts "  📂 File size: #{File.size(file_path)} bytes"
      puts "  🔍 Starting CSV parsing..."
      batch = []
      processed = 0
      batch_size = 5000
      
      process_psv_file_direct(file_path) do |row|
        locality_id = locality_lookup[row['LOCALITY_PID']]
        next unless locality_id
        
        # Fast lookup from memory
        street_info = @street_localities[row['STREET_LOCALITY_PID']]
        street_type_id = street_type_lookup[street_info&.dig(:street_type_code)] if street_info
        
        # Get geocode data
        geocode_info = @geocodes[row['ADDRESS_DETAIL_PID']]
        
        batch << {
          address_detail_pid: row['ADDRESS_DETAIL_PID'],
          street_locality_pid: row['STREET_LOCALITY_PID'],
          locality_id: locality_id,
          street_type_id: street_type_id,
          number_first: parse_integer(row['NUMBER_FIRST']),
          number_suffix: row['NUMBER_FIRST_SUFFIX'],
          number_last: parse_integer(row['NUMBER_LAST']),
          number_last_suffix: row['NUMBER_LAST_SUFFIX'],
          street_name: street_info&.dig(:street_name),
          street_class_code: street_info&.dig(:street_class_code),
          street_class_type: nil,
          level_type_code: row['LEVEL_TYPE_CODE'],
          level_type: nil,
          level_number_prefix: row['LEVEL_NUMBER_PREFIX'],
          level_number: parse_integer(row['LEVEL_NUMBER']),
          level_number_suffix: row['LEVEL_NUMBER_SUFFIX'],
          flat_type_code: row['FLAT_TYPE_CODE'],
          flat_type: nil,
          flat_number_prefix: row['FLAT_NUMBER_PREFIX'],
          flat_number: parse_integer(row['FLAT_NUMBER']),
          flat_number_suffix: row['FLAT_NUMBER_SUFFIX'],
          building_name: row['BUILDING_NAME'],
          lot_number_prefix: row['LOT_NUMBER_PREFIX'],
          lot_number: row['LOT_NUMBER'],
          lot_number_suffix: row['LOT_NUMBER_SUFFIX'],
          postcode: row['POSTCODE'],
          latitude: geocode_info&.dig(:latitude),
          longitude: geocode_info&.dig(:longitude),
          geocode_reliability_code: geocode_info&.dig(:geocode_type_code),
          confidence: row['CONFIDENCE'],
          legal_parcel_id: row['LEGAL_PARCEL_ID'],
          date_created: parse_date(row['DATE_CREATED']),
          date_last_modified: parse_date(row['DATE_LAST_MODIFIED']),
          date_retired: parse_date(row['DATE_RETIRED']),
          created_at: Time.current,
          updated_at: Time.current
        }
        
        if batch.size >= batch_size
          puts "  💾 Inserting batch of #{batch.size} records..."
          STDOUT.flush
          Address.insert_all(batch, unique_by: :address_detail_pid)
          processed += batch.size
          print "#{processed/1000}k "
          batch.clear
        end
      end
      
      # Insert remaining batch
      if batch.any?
        Address.insert_all(batch, unique_by: :address_detail_pid)
        processed += batch.size
      end
      
      puts "✅ #{processed} addresses"
    end
    
    @imported_counts[:addresses] = Address.count
    puts "✅ Imported #{@imported_counts[:addresses]} addresses"
  end

  def process_psv_file_direct(file_path)
    puts "  📖 Opening file for reading..."
    STDOUT.flush
    
    CSV.foreach(file_path, headers: true, col_sep: '|').with_index do |row, index|
      if index == 0
        puts "  ✅ First row parsed successfully"
        STDOUT.flush
      end
      
      yield(row)
      
      if (index + 1) % 10000 == 0
        print "."
        STDOUT.flush
      end
    end
    puts
    puts "  ✅ File parsing complete"
  end

  def process_psv_file(zip_file, entry)
    content = zip_file.read(entry)
    csv = CSV.parse(content, headers: true, col_sep: '|')
    
    csv.each_with_index do |row, index|
      yield(row)
      
      if (index + 1) % 10000 == 0
        print "."
        STDOUT.flush
      end
    end
    puts
  end

  def parse_integer(value)
    value.present? ? value.to_i : nil
  end

  def parse_date(value)
    value.present? ? Date.parse(value) : nil
  end

  def update_locality_postcodes_from_addresses
    puts "📮 Updating locality postcodes from address data..."
    
    # Update localities with postcodes from their addresses
    sql = <<~SQL
      UPDATE localities 
      SET postcode = subquery.postcode 
      FROM (
        SELECT DISTINCT locality_id, postcode 
        FROM addresses 
        WHERE postcode IS NOT NULL 
        GROUP BY locality_id, postcode
      ) AS subquery 
      WHERE localities.id = subquery.locality_id 
      AND (localities.postcode IS NULL OR localities.postcode = '')
    SQL
    
    ActiveRecord::Base.connection.execute(sql)
    puts "✅ Updated locality postcodes from address data"
  end

  def parse_decimal(decimal_string)
    return nil if decimal_string.blank?
    decimal_string.to_f
  end
end

def print_summary
  puts "\n🎉 GNAF Import Complete!"
  puts "=" * 50
  @imported_counts.each do |type, count|
    puts "#{type.to_s.humanize}: #{count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  puts "=" * 50
end

# Main seed execution
data_path = ENV['GNAF_DATA_PATH']

puts "GNAF Data Seeder"
puts "=================="

unless data_path
  puts "❌ GNAF_DATA_PATH environment variable is required"
  puts ""
  puts "Usage:"
  puts "  GNAF_DATA_PATH=/path/to/extracted/gnaf/data rails db:seed"
  puts ""
  exit 1
end

puts "Data path: #{data_path}"
puts

importer = GnafImporter.new(data_path)
success = importer.import!

unless success
  puts "\n💡 Usage: GNAF_DATA_PATH=/path/to/extracted/gnaf/data rails db:seed"
  exit 1
end
