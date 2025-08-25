# GNAF Data Viewer

A vibe-coded pile of slop for importing and querying the Geocoded National Address File (G-NAF) data locally.

⚠️ **Warning**: This application is a hastily assembled collection of code that somehow works. Proceed with caution.

## About G-NAF

The Geocoded National Address File (G-NAF) is Australia's authoritative, geocoded address file. It contains over 13 million Australian physical address records. The data is sourced from each state and territory's addressing authorities and is updated regularly.

## Data Source

Download the G-NAF data from: https://data.gov.au/data/dataset/geocoded-national-address-file-g-naf

The application expects the downloaded ZIP file to be available locally for seeding the database.

## Setup

### Prerequisites

* Ruby 3.4.4
* Rails 8.0+
* PostgreSQL 17 (SQLite gave up and went home)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Extract the G-NAF data ZIP file somewhere safe
5. Seed the database with G-NAF data (grab a coffee, this takes hours):
   ```bash
   GNAF_DATA_PATH=/path/to/extracted/gnaf/data rails db:seed
   ```

### Usage

Start the Rails server:
```bash
rails server
```

Navigate to `http://localhost:3000/localities` to browse localities and download CSV files.

## Known Issues & Quirks

- QLD address import may mysteriously stall (we're investigating)
- Code quality is questionable at best
- Error handling is optimistic
- Performance tuning was done by vibes only
- Postcodes are derived from address data because GNAF locality files are incomplete
- The import process uses "creative" PostgreSQL optimizations

## Database Schema

The application imports the following G-NAF data tables:
- Addresses
- Address Details
- Localities
- States
- Street Types
- And other related reference data

## Development

Run tests:
```bash
rails test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The G-NAF data is provided under the Creative Commons Attribution 4.0 International licence.
