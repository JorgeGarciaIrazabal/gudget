# database.py
# Handles database connection and session management.

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the database URL from environment variables
#SQLALCHEMY_DATABASE_URL = os.getenv("DB_STRING")
# Example: "postgresql://user:password@host:port/database"
# For Supabase, find this in your Supabase project settings under Database -> Connection string -> URI
SQLALCHEMY_DATABASE_URL = os.getenv("DB_STRING", "postgresql://postgres:your_password@db.your_supabase_co.supabase.co:5432/postgres")


if not SQLALCHEMY_DATABASE_URL:
    raise EnvironmentError("DB_STRING environment variable not set.")

# Create a SQLAlchemy engine
# `connect_args` can be used for SSL or other specific connection arguments if needed
# For Supabase, typically no special connect_args are needed unless you have specific network policies
engine = create_engine(
    SQLALCHEMY_DATABASE_URL
    # Example for PostgreSQL with SSL:
    # connect_args={"sslmode": "require"} if "supabase.co" in SQLALCHEMY_DATABASE_URL else {}
)

# Create a SessionLocal class, which will be used to create database sessions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for SQLAlchemy models
Base = declarative_base()

# Dependency to get a database session (can also be defined in main.py or a common deps.py)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()