import argparse
import configparser
import pandas as pd
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.types import Enum as SQLAlchemyEnum
from pandas.errors import EmptyDataError, ParserError
from enum import Enum
from sqlalchemy.types import UserDefinedType
import logging
import json

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AddressType(UserDefinedType):
    def get_col_spec(self):
        return "ADDRESS"

def clean_profit_margin(value):
    try:
        if isinstance(value, str):
            return int(value.strip('%'))
        return value
    except ValueError as e:
        logger.info(f"Error converting profit margin: {e}")
        return None
    
def clean_percentage(value):
    try:
        if isinstance(value, str):
            return float(value.strip('%'))
        return float(value)
    except ValueError as e:
        logger.info(f"Error converting percentage value: {e}")
        return None

def create_enum_from_postgres(engine, table_name, column_name):
    with engine.connect() as connection:
        query = text(f"""
            SELECT enum_range(NULL::{table_name}_{column_name})
        """)
        result = connection.execute(query).scalar()
        enum_values = result[1:-1].split(',')  # Remove parentheses and split
        return Enum(column_name, enum_values)

def get_table_info(engine, table_name):
    inspector = inspect(engine)
    columns = inspector.get_columns(table_name)
    table_info = {
        'columns': [col['name'] for col in columns],
        'types': {col['name']: col['type'] for col in columns},
        'enums': {}
    }
    
    for col in columns:
        if isinstance(col['type'], SQLAlchemyEnum):
            try:
                enum = create_enum_from_postgres(engine, table_name, col['name'])
                table_info['enums'][col['name']] = enum
            except SQLAlchemyError as e:
                logger.warn(f"Warning: Could not create enum for column {col['name']}: {e}")
    
    return table_info

def preprocess_data(data, engine, table_name):
    # Get the actual columns from the database table
    inspector = inspect(engine)
    db_columns = [column['name'] for column in inspector.get_columns(table_name)]

    logger.info(f"Database columns: {db_columns}")
    logger.info(f"CSV columns: {data.columns}")

    # Remove columns that don't exist in the database table
    data = data[[col for col in data.columns if col in db_columns]].copy()

    logger.info(f"Columns after filtering: {data.columns}")

    # Existing preprocessing steps
    percentage_columns = ['ip_percent_occupancy', 'profit_margin']
    for col in percentage_columns:
        if col in data.columns:
            data[col] = data[col].apply(clean_percentage)

    if 'room' in data.columns and 'type_of_data' in data.columns:
        data['room'] = list(zip(data['type_of_data'], data['room']))
    elif 'room' in data.columns:
        data['room'] = list(zip(['service line'] * len(data), data['room']))

    if 'id' in data.columns:
        data['id'] = data['id'].apply(int)
        data.drop('id', axis=1, inplace=True)

    if 'fin_years' in data.columns:
        data['fin_years'] = data['fin_years'].apply(lambda x: json.dumps([x]) if pd.notnull(x) else '[]')

    # Check for any remaining columns with object dtype and convert to string
    for col in data.select_dtypes(include=['object']).columns:
        data[col] = data[col].astype(str)

    logger.info(f"Final preprocessed data shape: {data.shape}")
    logger.info(f"Final preprocessed columns: {data.columns}")
    logger.info(f"Data types: {data.dtypes}")

    return data

def parse_arguments():
    parser = argparse.ArgumentParser(description='Import CSV data into a database table')
    parser.add_argument('file_path', help='Path to the CSV file')
    parser.add_argument('table_name', help='Name of the database table')
    return parser.parse_args()

def read_config():
    config = configparser.ConfigParser()
    if not config.read('config.ini'):
        raise FileNotFoundError("Error: Could not read 'config.ini' file.")
    
    # Use raw string for db_url
    db_url = config.get('database', 'db_url', raw=True)
    
    # Create a new config with just the raw db_url
    new_config = configparser.ConfigParser()
    new_config['database'] = {'db_url': db_url}
    
    return new_config

def create_database_engine(config):
    try:
        db_url = config.get('database', 'db_url')
        return create_engine(db_url)
    except (configparser.NoSectionError, configparser.NoOptionError) as e:
        raise ValueError(f"Error reading database configuration: {e}")

def insert_data(engine, table_name, data):
    with engine.begin() as connection:
        try:
            data.to_sql(table_name, con=connection, if_exists='append', index=False)
            logger.info(f"Inserted {len(data)} rows into {table_name}")
        except Exception as e:
            logger.error(f"Error inserting data: {e}")
            logger.error(f"Data sample: {data.head()}")
            raise

def main():
    args = parse_arguments()
    config = read_config()
    engine = create_database_engine(config)
    
    try:
        # Log the file being processed
        logger.info(f"Processing file: {args.file_path}")
        
        # Read the CSV file
        data = pd.read_csv(args.file_path)
        logger.info(f"CSV data shape: {data.shape}")
        logger.info(f"CSV columns: {data.columns}")
        
        # Preprocess the data
        data = preprocess_data(data, engine, args.table_name)
        logger.info(f"Preprocessed data shape: {data.shape}")
        logger.info(f"Preprocessed data columns: {data.columns}")
        
        # Insert the data
        insert_data(engine, args.table_name, data)
        
        # Verify insertion
        with engine.connect() as connection:
            result = connection.execute(text(f"SELECT COUNT(*) FROM {args.table_name}")).scalar()
            logger.info(f"Total rows in {args.table_name} after insertion: {result}")
        
        logger.info("Data inserted successfully.")
    except (EmptyDataError, ParserError) as e:
        logger.error(f"Error reading CSV file: {e}")
    except SQLAlchemyError as e:
        logger.error(f"An SQLAlchemy error occurred: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
    finally:
        engine.dispose()

if __name__ == '__main__':
    main()