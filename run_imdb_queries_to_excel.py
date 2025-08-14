#!/usr/bin/env python3
"""
IMDB Project — Run Queries (Q1..Q50) and Export Results
-------------------------------------------------------
- Loads schema & data from: IMDB+dataset+import.sql
- Runs setup / cleaning steps from: IMDB_SQL_Solved_Project_*.sql (before Segment 1)
- Detects Q01..Q50 queries in the "Solved" SQL by markers like:  -- Q10 — Find ...
- Exports each result both to:
    * Excel workbook with separate sheets named "Q01_...", "Q02_...", etc.
    * Individual CSV files in an output folder.

USAGE (install requirements first): 
    pip install mysql-connector-python pandas openpyxl

    # Example (password inline):
    python run_imdb_queries_to_excel.py --host localhost --user root --password "project@sql" \
        --database imdb \
        --dataset_sql "IMDB+dataset+import.sql" \
        --solved_sql "IMDB_SQL_Solved_Project_SahilVerma_All_Segments.sql" \
        --excel_out "IMDB_Q01_Q50_Results.xlsx" \
        --csv_dir "csv_results"

    # Safer example (prompt for password instead of --password):
    python run_imdb_queries_to_excel.py --host localhost --user root \
        --database imdb \
        --dataset_sql "IMDB+dataset+import.sql" \
        --solved_sql "IMDB_SQL_Solved_Project_SahilVerma_All_Segments.sql" \
        --excel_out "IMDB_Q01_Q50_Results.xlsx" \
        --csv_dir "csv_results"

Notes:
- The script assumes you have a running MySQL (or MariaDB) instance and credentials.
- It is idempotent-ish: it executes your dataset file; use --skip_setup to skip reloading.
"""

import argparse
import getpass
import os
import re
import sys
from typing import List, Tuple, Dict

import pandas as pd
import mysql.connector
from mysql.connector import errorcode

def read_text(path: str) -> str:
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        return f.read()

def split_mysql_statements(sql_text: str) -> List[str]:
    """
    Naive but practical splitter that respects quotes and semicolons.
    Keeps lines that start with '-- Q' or contain 'Segment <n>' labels.
    Strips other comments.
    """
    lines = sql_text.splitlines()
    kept = []
    in_block = False
    for line in lines:
        l = line
        if '/*' in l and '*/' not in l:
            in_block = True
        if in_block:
            if '*/' in l:
                in_block = False
            continue
        l = re.sub(r'/\*.*?\*/', ' ', l)  # inline /* ... */
        if re.match(r'\s*--\s*Q\d+', l, flags=re.IGNORECASE) or re.search(r'Segment\s+\d+', l, flags=re.IGNORECASE):
            kept.append(l)
            continue
        l = re.sub(r'--.*$', '', l)  # strip other -- comments
        kept.append(l)
    text = '\n'.join(kept)

    stmts = []
    buff = []
    in_single = False
    in_double = False
    esc = False
    for ch in text:
        if ch == "'" and not in_double and not esc:
            in_single = not in_single
        elif ch == '"' and not in_single and not esc:
            in_double = not in_double
        if ch == ';' and not in_single and not in_double:
            stmts.append(''.join(buff).strip())
            buff = []
        else:
            buff.append(ch)
        esc = (ch == '\\' and not esc)
    if buff:
        tail = ''.join(buff).strip()
        if tail:
            stmts.append(tail)
    return [s for s in stmts if s.strip()]

def extract_setup_and_queries(solved_sql_text: str) -> Tuple[List[str], Dict[str, Dict[str, str]]]:
    """
    Return:
      - setup_statements: list of SQL statements to run BEFORE Q1 (i.e., everything before 'Segment 1')
      - queries: dict keyed by 'Q01'.., value contains {'label': 'Q01 — ...', 'sql': 'SELECT ...'}
    """
    raw = solved_sql_text
    statements = split_mysql_statements(raw)

    # Separate setup vs rest by first "Segment 1"
    seg1_idx = None
    for i, s in enumerate(statements):
        if re.search(r'\bSegment\s*1\b', s, flags=re.IGNORECASE):
            seg1_idx = i
            break
    if seg1_idx is None:
        setup_statements = statements
    else:
        setup_statements = statements[:seg1_idx]

    # Use raw text to capture Q labels & blocks
    q_pat = re.compile(r'^\s*--\s*(Q\d+)\s*[—\-–]*\s*(.*)$', re.IGNORECASE | re.MULTILINE)
    q_positions = [(m.group(1).upper(), m.start(), m.group(0)) for m in q_pat.finditer(raw)]
    queries: Dict[str, Dict[str, str]] = {}

    for idx, (qkey, start_pos, label_line) in enumerate(q_positions):
        end_pos = q_positions[idx + 1][1] if idx + 1 < len(q_positions) else len(raw)
        block = raw[start_pos:end_pos]
        m = re.search(r'(?is)\b(SELECT|WITH\b.+?SELECT)\b.*?;', block)
        if not m:
            continue
        sql = m.group(0).strip().rstrip(';')
        qnum = int(re.sub(r'\D', '', qkey))
        qstd = f"Q{qnum:02d}"
        label = label_line.strip().lstrip('-').strip()
        queries[qstd] = {"label": label, "sql": sql}

    return setup_statements, queries

def run_statements(cur, statements: List[str], echo=False):
    for s in statements:
        s2 = s.strip()
        if not s2:
            continue
        if echo:
            print(f"-- Executing: {s2[:120]}{'...' if len(s2)>120 else ''}")
        try:
            cur.execute(s2)
            while True:
                _ = cur.fetchall() if cur.with_rows else None
                if not cur.next_result():
                    break
        except mysql.connector.Error as e:
            print(f"[WARN] Skipping failed statement:\n{s2}\nError: {e}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--host', default='localhost')
    ap.add_argument('--port', type=int, default=3306)
    ap.add_argument('--user', required=True)
    ap.add_argument('--password', help='If omitted, you will be prompted securely.')
    ap.add_argument('--database', default='imdb')
    ap.add_argument('--dataset_sql', required=True)
    ap.add_argument('--solved_sql', required=True)
    ap.add_argument('--excel_out', default='IMDB_Q01_Q50_Results.xlsx')
    ap.add_argument('--csv_dir', default='csv_results')
    ap.add_argument('--skip_setup', action='store_true')
    args = ap.parse_args()

    if not args.password:
        args.password = getpass.getpass(prompt='MySQL password: ')

    dataset_sql_text = read_text(args.dataset_sql)
    solved_sql_text = read_text(args.solved_sql)

    setup_statements, queries = extract_setup_and_queries(solved_sql_text)

    # First connect without choosing DB so dataset file can create it
    try:
        cnx = mysql.connector.connect(
            host=args.host, port=args.port,
            user=args.user, password=args.password,
            autocommit=True
        )
    except mysql.connector.Error as err:
        print(f"Error connecting to MySQL: {err}")
        sys.exit(1)

    cur = cnx.cursor()

    if not args.skip_setup:
        print(">> Running dataset schema & seed ...")
        run_statements(cur, split_mysql_statements(dataset_sql_text), echo=True)
        print(">> Running solved pre-Segment-1 setup ...")
        run_statements(cur, setup_statements, echo=True)
    else:
        print(">> Skipping setup (--skip_setup)")

    # USE database
    try:
        cur.execute(f"USE `{args.database}`;")
    except mysql.connector.Error as e:
        print(f"Failed to USE database {args.database}: {e}")
        sys.exit(1)

    os.makedirs(args.csv_dir, exist_ok=True)
    writer = pd.ExcelWriter(args.excel_out, engine='openpyxl')

    print(f">> Executing {len(queries)} queries ...")
    for qkey in sorted(queries.keys()):
        label = queries[qkey]['label']
        sql = queries[qkey]['sql']
        print(f"[{qkey}] {label}")

        try:
            cur.execute(sql)
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description] if cur.description else []
            df = pd.DataFrame(rows, columns=cols)
        except mysql.connector.Error as e:
            df = pd.DataFrame({'error': [str(e)], 'query': [sql]})

        # Sheet name (<=31 chars)
        sheet_name = f"{qkey}_{label}"
        for bad, repl in [('/', '_'), ('\\', '_'), (':', ' '), ('*', ' '), ('?', ' '), ('[', '('), (']', ')')]:
            sheet_name = sheet_name.replace(bad, repl)
        if len(sheet_name) > 31:
            sheet_name = sheet_name[:31]

        try:
            df.to_excel(writer, index=False, sheet_name=sheet_name)
        except Exception:
            df.to_excel(writer, index=False, sheet_name=qkey)

        df.to_csv(os.path.join(args.csv_dir, f"{qkey}.csv"), index=False, encoding='utf-8')

    writer.close()
    cur.close()
    cnx.close()
    print(f">> Done. Excel: {args.excel_out} | CSV dir: {args.csv_dir}")

if __name__ == '__main__':
    main()
