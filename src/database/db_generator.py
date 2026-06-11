import sqlite3
import random
import logging
from argparse import ArgumentParser
from datetime import datetime, timedelta
from common.config_manager import ConfigManager

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DBGenerator")


class EPPDatabaseGenerator:
    def __init__(self):
        self.config = ConfigManager()

        self.version = self.config.version
        self.db_path = self.config.get_versioned_db_path()

        # CONFIGURABLE CONSTANTS
        self.start_date = datetime.strptime("2026-01-01", "%Y-%m-%d")
        self.end_date = datetime.strptime("2026-03-01", "%Y-%m-%d")
        self.records_per_day = 2000

        # SAME VALUES AS TEST DATA (no quotes)
        self.COLUMN_VALUES = {
            "epp_sla": {
                "command": ["ADD-DOMAIN", "CHECK-DOMAIN", "MOD-DOMAIN", "RENEW-DOMAIN", "TRANSFER-DOMAIN"],
                "tld": ["com", "net", "io", "org", "info", "biz"],
                "result": ["SUCCESS", "FAILURE", "TIMEOUT", "ERROR"],
                "failed_reason": ["CONNECTION_TIMEOUT", "AUTH_FAILED", "INVALID_TLD", "QUOTA_EXCEEDED"]
            },
            "epp_client": {
                "client_location": ["USA", "EU", "ASIA", "AUSTRALIA", "LATAM", "AFRICA"],
                "client_group": ["Gold", "Silver", "Internal", "VIP", "Reseller"],
                "client_ip_version": ["IPv4", "IPv6"]
            },
            "epp_release": {
                "release_location": ["Global", "Regional", "Staging"]
            }
        }

    # ==============================================================================
    # TABLE MANAGEMENT
    # ==============================================================================

    def create_tables(self, conn):
        cursor = conn.cursor()

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS epp_sla (
            date TEXT,
            hour INTEGER,
            command TEXT,
            tld TEXT,
            response_time REAL,
            result TEXT,
            volume INTEGER,
            client_name TEXT,
            failed_reason TEXT
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS epp_client (
            client_name TEXT PRIMARY KEY,
            client_ip_version TEXT,
            client_group TEXT,
            client_location TEXT
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS epp_release (
            release_name TEXT,
            release_start TEXT,
            release_end TEXT,
            release_location TEXT
        );
        """)

        conn.commit()

    def drop_tables(self, conn):
        cursor = conn.cursor()
        for table in ["epp_sla", "epp_client", "epp_release"]:
            cursor.execute(f"DROP TABLE IF EXISTS {table}")
        conn.commit()

    def _table_row_count(self, conn, table):
        cursor = conn.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        return cursor.fetchone()[0]

    # ==============================================================================
    # CLIENTS
    # ==============================================================================

    def seed_clients(self, conn):
        cursor = conn.cursor()

        rows = []
        for i in range(50):
            rows.append((
                f"CLIENT_{i}",
                random.choice(self.COLUMN_VALUES["epp_client"]["client_ip_version"]),
                random.choice(self.COLUMN_VALUES["epp_client"]["client_group"]),
                random.choice(self.COLUMN_VALUES["epp_client"]["client_location"])
            ))

        cursor.executemany("""
        INSERT OR IGNORE INTO epp_client VALUES (?, ?, ?, ?)
        """, rows)

        conn.commit()

    # ==============================================================================
    # RELEASES (15-DAY WINDOWS)
    # ==============================================================================

    def seed_releases(self, conn):
        cursor = conn.cursor()

        rows = []
        current_start = self.start_date

        while current_start <= self.end_date:
            current_end = current_start + timedelta(days=14)

            rows.append((
                f"Release-{current_start.strftime('%Y%m%d')}",
                current_start.strftime("%Y-%m-%d"),
                current_end.strftime("%Y-%m-%d"),
                random.choice(self.COLUMN_VALUES["epp_release"]["release_location"])
            ))

            current_start += timedelta(days=15)

        cursor.executemany("""
        INSERT INTO epp_release VALUES (?, ?, ?, ?)
        """, rows)

        conn.commit()

    # ==============================================================================
    # SLA DATA (FULL COVERAGE + RANDOM FILL)
    # ==============================================================================

    def seed_sla(self, conn):
        cursor = conn.cursor()

        commands = self.COLUMN_VALUES["epp_sla"]["command"]
        tlds = self.COLUMN_VALUES["epp_sla"]["tld"]
        results = self.COLUMN_VALUES["epp_sla"]["result"]
        reasons = self.COLUMN_VALUES["epp_sla"]["failed_reason"]

        clients = [f"CLIENT_{i}" for i in range(50)]

        current_date = self.start_date

        while current_date <= self.end_date:
            date_str = current_date.strftime("%Y-%m-%d")

            rows = []

            # --- FULL COVERAGE ---
            for cmd in commands:
                for tld in tlds:
                    for hour in range(24):
                        rows.append((
                            date_str,
                            hour,
                            cmd,
                            tld,
                            round(random.uniform(10, 2000), 2),
                            random.choice(results),
                            random.randint(1, 5000),
                            random.choice(clients),
                            random.choice(reasons)
                        ))

            # --- FILL TO TARGET ---
            while len(rows) < self.records_per_day:
                rows.append((
                    date_str,
                    random.randint(0, 23),
                    random.choice(commands),
                    random.choice(tlds),
                    round(random.uniform(10, 2000), 2),
                    random.choice(results),
                    random.randint(1, 5000),
                    random.choice(clients),
                    random.choice(reasons)
                ))

            cursor.executemany("""
            INSERT INTO epp_sla VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, rows)

            logger.info(f"{date_str}: inserted {len(rows)} rows")

            current_date += timedelta(days=1)

        conn.commit()

    # ==============================================================================
    # MAIN ENTRY
    # ==============================================================================

    def initialize(self, reset: bool = False):
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

        with sqlite3.connect(self.db_path) as conn:
            if reset:
                logger.info(f"Resetting database at {self.db_path}")
                self.drop_tables(conn)

            self.create_tables(conn)

            if self._table_row_count(conn, "epp_client") == 0:
                self.seed_clients(conn)

            if self._table_row_count(conn, "epp_release") == 0:
                self.seed_releases(conn)

            if self._table_row_count(conn, "epp_sla") == 0:
                logger.info(f"Seeding SLA data...")
                self.seed_sla(conn)

        logger.info(f"Database initialized successfully at: {self.db_path}")


# ==============================================================================
# ENTRY
# ==============================================================================

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--reset", action="store_true", help="Drop and recreate tables")
    args = parser.parse_args()

    gen = EPPDatabaseGenerator()
    gen.initialize(reset=args.reset)