<img width="1536" height="1024" alt="ChatGPT Image Aug 14, 2025, 11_57_55 AM" src="https://github.com/user-attachments/assets/0b3c0f5b-7230-415e-8059-1d146ac8808e" />

# 🎬 IMDB Movies — Advanced SQL Analysis with AI Insights
# SQL-RSVP-Movies-Project
Advanced SQL case study on IMDB movie data, answering 50 real-world business questions with AI-enhanced insights, data cleaning, and a structured query workflow — based on the RSVP Movies project.

> **A complete SQL case study based on RSVP Movies** — analyzing global movie trends, ratings, genres, and box office performance using MySQL.  
> Enhanced with AI-generated summaries, insights tables, and a clear project flowchart.

> ![MySQL](https://img.shields.io/badge/Database-MySQL-blue?logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/Query%20Language-SQL-lightgrey?logo=databricks&logoColor=white)
![Excel](https://img.shields.io/badge/Data-Excel-green?logo=microsoft-excel&logoColor=white)
![AI Assisted](https://img.shields.io/badge/AI%20Support-ChatGPT-ff69b4?logo=openai&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)


---

## 📌 Introduction

The **IMDB Movies SQL Project** is a comprehensive analysis of movie industry data, undertaken as part of the RSVP Movies case study.  
The project focuses on answering **50 real-world business questions** to help decision-makers understand:

- 🎭 Genre popularity trends
- ⭐ Actor & director performance
- 💰 Box office patterns
- 🌍 Country-wise production insights

---

## 🧑‍💼 About the Author

Hi, I’m **Sahil Verma** — a passionate and detail-oriented **Data Analyst** with a focus on **SQL, Python, Data Visualization, and Business Insights**.  
With experience in both **technical analysis** and **business communication**, I specialize in turning raw data into actionable stories that drive decision-making.

This project represents my dedication to **structured thinking**, **clean code**, and **insightful storytelling** in the data domain.

---

## 🎯 Problem Statement

RSVP Movies, after the success of their movie *"The Sky Is Pink"*, wanted to **produce a new international movie**.  
They required **data-driven insights** to make decisions regarding:

- **Target audience preferences**  
- **Optimal genres & languages**
- **High-performing actors & directors**
- **Profitable production countries**

SQL was chosen for its **efficiency, reliability, and scalability** in handling structured datasets.

---

## 📂 Dataset Description

The database contains **6 key tables**:

| Table Name        | Rows   | Description |
|-------------------|--------|-------------|
| `movie`           | 7,997  | Movie details (title, year, languages, gross income) |
| `ratings`         | 7,997  | Ratings & votes |
| `genre`           | 14,662 | Genre mapping for movies |
| `names`           | 25,735 | Actor/Director names |
| `director_mapping`| 3,867  | Mapping between movies & directors |
| `role_mapping`    | 15,615 | Mapping between movies & actors |

---

## 🗺 Project Flowchart (ERD)

**ERD Placeholder** — *(Add your image here)*  
`![ERD Flowchart](flowchart.png)`

**Legend:**
- 🎬 **movie** — Central table containing main attributes
- 🎭 **genre** — Linked to `movie_id` for category
- ⭐ **names** — Linked via mapping tables to identify actors/directors
- 📊 **ratings** — Stores audience feedback
- 🎥 **director_mapping / role_mapping** — Many-to-many relationship mapping

---

## 🛠 Methodology & Workflow

### Step 1 — Database Setup
- Imported SQL file into **MySQL Workbench**
- Verified schema and row counts

### Step 2 — Data Cleaning
- Created additional columns (e.g., `worldwide_gross_num`)
- Removed currency symbols & formatted numbers
- Split multi-valued fields (countries, languages) into separate mapping tables

### Step 3 — Query Segmentation
The project was split into **7 segments**:

| Segment | Query Range | Objective |
|---------|-------------|-----------|
| 1️⃣ | Q1–Q9   | Basic movie listings, filtering, and counts |
| 2️⃣ | Q10–Q17 | Actor, director, and genre-specific stats |
| 3️⃣ | Q18–Q23 | Ratings & revenue patterns |
| 4️⃣ | Q24–Q29 | Complex subqueries & comparisons |
| 5️⃣ | Q30–Q38 | Aggregations & advanced joins |
| 6️⃣ | Q39–Q45 | Box office & global trends |
| 7️⃣ | Q46–Q50 | Special metrics & top performers |

---

## 📊 AI-Enhanced Segment Summary

| Segment | Focus Area | Example Insights |
|---------|------------|------------------|
| **1** | Basic filtering | 📅 Year-wise releases trend |
| **2** | People analytics | 🎥 Most prolific directors |
| **3** | Revenue & ratings | 💰 Highest-grossing titles |
| **4** | Comparative analysis | 🏆 Genre rating comparisons |
| **5** | Aggregations | 🌍 Country-wise revenue share |
| **6** | Advanced joins | ⭐ Actor box office dominance |
| **7** | Custom KPIs | ⏱ Rating per minute ratio |

---

## 🔍 Key Insights & Recommendations

### 🎭 Genre Trends
- **Drama** & **Comedy** dominate production volumes
- Action movies yield **higher average revenue**

### ⭐ Talent Insights
- Certain directors consistently achieve **above-average ratings**
- A handful of actors bring **global box office appeal**

### 🌍 Geographic Patterns
- US & India lead in production count
- Multilingual releases show **broader audience reach**

### 💰 Business Implications
- Focus on **Drama/Action** genres for international market
- Engage **top-rated directors** for higher audience trust
- Leverage **multi-country filming** for diverse market penetration

---

## 🛠 Tools & Technologies Used

| Tool/Tech        | Purpose |
|------------------|---------|
| MySQL Workbench  | SQL query execution |
| SQL              | Data extraction, transformation, and analysis |
| Excel            | Dataset exploration & ERD |
| AI (ChatGPT)     | Query planning, insights, and documentation |

---

## 🚀 How to Run This Project

1. **Clone Repository**
   ```bash
   git clone https://github.com/yourusername/imdb-sql-analysis.git

## 💬 For Aspiring Data Analysts

If you’re starting your SQL journey, I’ve included an IMDB+question.sql file containing real business questions from this project.
Try solving them before checking my solutions — it’s the best way to learn! 🚀

## 🏁 Ending Note

This project reflects my dedication to clean data, structured analysis, and actionable insights.
From importing raw datasets to delivering business-ready intelligence, every step here is designed with clarity and precision.

### 📢 If you’re an aspiring analyst — remember, SQL is not just about queries, it’s about asking the right questions.

— Sahil Verma
Data Analyst & SQL Enthusiast
