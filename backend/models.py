# models.py
# Defines SQLAlchemy ORM models.

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func # For default timestamp

from database import Base # Import Base from database.py

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    # Define one-to-many relationships (optional, but good for ORM features)
    incomes = relationship("Income", back_populates="owner")
    expenses = relationship("Expense", back_populates="owner")

class Income(Base):
    __tablename__ = "incomes"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, index=True)
    amount = Column(Float, nullable=False)
    date = Column(DateTime(timezone=True), server_default=func.now()) # Auto-set to current time on creation
    owner_id = Column(Integer, ForeignKey("users.id"))

    # Define the many-to-one relationship
    owner = relationship("User", back_populates="incomes")

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, index=True)
    amount = Column(Float, nullable=False)
    category = Column(String, index=True, nullable=True) # e.g., Food, Transport, Utilities
    date = Column(DateTime(timezone=True), server_default=func.now()) # Auto-set to current time on creation
    owner_id = Column(Integer, ForeignKey("users.id"))

    # Define the many-to-one relationship
    owner = relationship("User", back_populates="expenses")