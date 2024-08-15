# Enviah Data Importer

This script is designed to import data from a CSV file into a PostgreSQL database.

## Setup

### Unix-based systems (macOS, Linux)

1. Ensure you have Python 3.x installed.
2. Run the setup script:
   ```
   ./setup.sh
   ```
3. Activate the virtual environment:
   ```
   source venv/bin/activate
   ```

### Windows

1. Ensure you have Python 3.x installed.
2. Run the setup script:
   ```
   setup.bat
   ```
3. Activate the virtual environment:
   ```
   venv\Scripts\activate
   ```

## Development

Always make sure to activate the virtual environment before working on the project:

- Unix-based: `source venv/bin/activate`
- Windows: `venv\Scripts\activate`

To deactivate the virtual environment when you're done, simply run:
```
deactivate
```

## Usage

To use the script, follow these steps:

1. Open a terminal or command prompt.
2. Navigate to the directory where the script is located.
3. Run the following command:

```
python import.py <file_path> <table_name>
```

Replace `<file_path>` with the path to the CSV file you want to import, and `<table_name>` with the name of the table in the database where you want to import the data.

For example, if you have a CSV file named `data.csv` in the current directory and you want to import it into a table named `service_line` in the `enviah-db` database, you would run the following command:

```
python import.py data.csv service_line
```

## Configuration

The script reads its configuration from a file named `config.ini`. This file should be located in the same directory as the script. The configuration file contains the following settings:

- `db_url`: The URL of the PostgreSQL database you want to connect to. This URL should include the database name, username, password, and other necessary information.

## Example

To illustrate how to use the script, let's assume you have a CSV file named `data.csv` in the current directory with the following contents:

```
id,system_id,campus_id,address,name,type_of_building,additional_building_investments_needed,engineering_score,roofing_facade,electrical,plumbing,annual_building_costs,annual_rent,lease_or_owned
1,1,1,"129 Jefferson Avenue SE, Grand Rapids, MI 49503",Trinity Health ,Inpatient,100000,57,2,2,2,1000000,20000,Lease
2,2,1,"129 Jefferson Avenue SE, Grand Rapids, MI 49503",Trinity Health ,Inpatient,100000,57,2,2,2,1000000,20000,Lease
3,3,1,"129 Jefferson Avenue SE, Grand Rapids, MI 49503",Trinity Health ,Inpatient,100000,57,2,2,2,1000000,20000,Lease
4,4,1,"129 Jefferson Avenue SE, Grand Rapids, MI 49503",Trinity Health ,Inpatient,100000,57,2,2,2,1000000,20000,Lease
```

To import this data into the `service_line` table in the `enviah-db` database, you would run the following command:

```
python import.py data.csv service_line
```

This command will insert the data into the `service_line` table in the `enviah-db` database. The script will also verify the insertion by checking the number of rows in the table.

## Conclusion

The Enviah Data Importer is a powerful tool that can be used to import data from a CSV file into a PostgreSQL database. By following the steps outlined in this guide, you can easily use the script to import your data into the database. Remember to always verify the data after importing it to ensure accuracy and integrity.

## Working Table Imports
- [X] Building
- [X] Campus
- [X] Financial - Problem with trigger function
- [X] Floor
- [X] Project Costs
- [ ] Service Line
- [X] Standards
- [X] System
