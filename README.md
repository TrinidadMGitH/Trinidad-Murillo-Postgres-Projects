# Trinidad-Murillo-Postgres-Projects
# Fish Processing & Operations Analysis (PostgreSQL)

## Overview

This project demonstrates my ability to use PostgreSQL to design a relational database and solve a business operations problem using SQL.

The project models a fictional fish processing operation in La Jolla, California. It combines estimated fishing yields, environmental conditions, and employee productivity data to determine efficient processing schedules and estimate daily profits.

Rather than simply querying existing data, this project focuses on using SQL to model a real-world business scenario and generate meaningful operational insights.

---

## Objectives

* Design a relational PostgreSQL database
* Model a business workflow using SQL
* Calculate operational profitability
* Optimize employee scheduling based on productivity
* Demonstrate advanced SQL techniques

---

## Database Structure

The database consists of multiple related components including:

* **Fishing Conditions**

  * Daily tide information
  * Moon phase
  * Estimated morning and evening fish yields
  * Fishing condition classifications

* **Employee Data**

  * Hourly wage
  * Processing speed (lbs/hour)
  * Revenue generated per pound processed

* **Profit View**

  * Estimated processing hours
  * Pounds processed
  * Remaining workload
  * Profit calculations
  * Daily operational summaries

---

## SQL Concepts Demonstrated

This project demonstrates practical experience with:

* Database creation
* Table design
* Views
* Common Table Expressions (CTEs)
* Recursive query structure
* Window Functions
* CROSS JOINs
* CASE expressions
* Aggregate calculations
* Ranking functions
* Mathematical functions
* Business logic implementation

---

## Business Problem

Given estimated daily fish catches and employee productivity, determine:

* Which employees generate the highest profit
* How many hours should each employee work
* How much fish can be processed
* Estimated operational profit for each day

The project simulates a scheduling and profitability problem that could be encountered in production planning or operations management.

---

## Key Features

* Calculates profit per pound after labor costs
* Ranks employees by processing profitability
* Allocates work based on productivity
* Estimates remaining inventory after processing
* Produces a summarized profit view for operational decision making

---

## Skills Demonstrated

* Relational database design
* Business analytics
* SQL query development
* Data modeling
* Operational optimization
* Analytical problem solving

---

## What I Learned

Through this project I gained hands-on experience designing relational databases and applying PostgreSQL to solve business-oriented analytical problems. I strengthened my understanding of SQL by combining multiple techniques—including CTEs, window functions, joins, views, and conditional logic—to build a complete analytical workflow rather than writing isolated queries.

---

## Future Improvements

Potential enhancements include:

* Normalizing additional tables
* Adding stored procedures and triggers
* Creating indexes to improve query performance
* Building dashboards with Power BI or Tableau
* Automating data imports
* Expanding profitability analysis with seasonal trends

---

## Technologies Used

* PostgreSQL
* SQL
* Git
* GitHub

---

*This project was completed as part of my ongoing effort to build practical SQL and database skills while developing a portfolio for entry-level data analytics opportunities.*
