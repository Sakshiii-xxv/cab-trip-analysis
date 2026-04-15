# Cab Ride Hailing — Trip Analysis & Operational Insights

## Project Overview
End-to-end SQL analytics project analyzing 1,200+ cab trip records across 8 Indian cities to uncover operational inefficiencies and revenue patterns using advanced SQL, Python, and Power BI.

## Tools Used
| Tool | Purpose |
|------|---------|
| PostgreSQL + DBeaver | Database management and SQL analysis |
| Python 3 | Synthetic dataset generation |
| Power BI / Excel | Dashboarding and visualization |
| Git + GitHub | Version control |

## Dataset Overview
| Table | Rows | Description |
|-------|------|-------------|
| trips | 1,200 | Core fact table — includes fare, distance, and trip status |
| drivers | 50 | Driver profiles, ratings, and vehicle types |
| cities | 8 | Metro and Tier-2 city details |
| cancellations | ~240 | Cancelled and no-show trip records |
| surge_pricing | 448 | Time-slot-based surge multiplier logs |

## ER DIAGRAM
![ER DIAGRAM](docs/er_diagram.png)

**Time Period:** January 2024 – December 2024

## Key Business Insights
- Identified 34% cancellation concentration in outer zones
- Surge pricing contributed 22% of total revenue despite only 9% of trips
- Top 10% of drivers generated 38% of total revenue
- Detected 3 high-demand zones with a 40%+ supply gap

## How to Run This Project
1. Clone this repository
2. Run `python data/generate_data.py` to generate CSV files
3. Open DBeaver → connect to PostgreSQL → open `cab_analysis` database
4. Execute `sql/01_schema.sql` to create tables
5. Import CSV files using DBeaver Import Wizard
6. Run analysis queries in order: `03 → 04 → 05`

## Author
**Sakshi**