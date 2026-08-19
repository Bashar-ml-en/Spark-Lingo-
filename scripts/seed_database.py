"""Seed disposable local or staging databases only.

This legacy demo seeder uses a service-role key and therefore bypasses Row
Level Security. It intentionally has no production mode, no default URL, and
does not send a request unless an operator supplies an explicit confirmation.
Use the Supabase CLI and the reviewed ``scripts/seed.sql`` for normal local
development. See ``supabase/README.md`` before running this script.
"""

from __future__ import annotations

import argparse
import os
import sys
import uuid
from dataclasses import dataclass
from typing import Iterable, Optional
from urllib.parse import urlparse

import requests


class ConfigurationError(ValueError):
    """Raised when a seed target does not meet the non-production guardrails."""


@dataclass(frozen=True)
class SeedTarget:
    environment: str
    base_url: str
    service_role_key: Optional[str]


def required_environment(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise ConfigurationError(f"Missing required environment variable: {name}.")
    return value


def project_ref_is_valid(project_ref: str) -> bool:
    return (
        len(project_ref) == 20
        and project_ref.isascii()
        and project_ref.isalnum()
        and project_ref == project_ref.lower()
    )


def parse_target_url(value: str):
    parsed = urlparse(value.strip())
    if (
        not parsed.scheme
        or not parsed.hostname
        or parsed.username
        or parsed.password
        or parsed.query
        or parsed.fragment
        or parsed.path not in ("", "/")
    ):
        raise ConfigurationError("The seed URL must be a bare base URL with no credentials, path, query, or fragment.")
    return parsed


def configured_target(args: argparse.Namespace) -> SeedTarget:
    url_value = args.url or required_environment("SPARK_LINGO_SEED_URL")
    parsed = parse_target_url(url_value)
    environment = args.environment

    if environment == "local":
        if parsed.scheme != "http" or parsed.hostname not in {"localhost", "127.0.0.1", "::1"}:
            raise ConfigurationError("Local seeding may target only an HTTP loopback Supabase instance.")
    elif environment == "staging":
        staging_ref = required_environment("SPARK_LINGO_STAGING_PROJECT_REF")
        production_ref = required_environment("SPARK_LINGO_PRODUCTION_PROJECT_REF")
        supplied_ref = args.project_ref or staging_ref

        if not all(project_ref_is_valid(ref) for ref in (staging_ref, production_ref, supplied_ref)):
            raise ConfigurationError("A configured Supabase project reference is invalid.")
        if supplied_ref != staging_ref:
            raise ConfigurationError("The supplied project reference does not match the configured staging project.")
        if staging_ref == production_ref:
            raise ConfigurationError("Staging and production project references must be different.")
        if parsed.scheme != "https" or parsed.hostname != f"{staging_ref}.supabase.co":
            raise ConfigurationError("Staging seed URL does not exactly match the configured staging project.")
    else:  # argparse protects this branch; keep it fail-closed for programmatic use.
        raise ConfigurationError("Only local and staging seed environments are supported.")

    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    return SeedTarget(environment=environment, base_url=parsed.geturl().rstrip("/"), service_role_key=key or None)


def insert_data(target: SeedTarget, table: str, data: object) -> None:
    if not target.service_role_key:
        raise ConfigurationError("SUPABASE_SERVICE_ROLE_KEY is required when --apply is used.")

    headers = {
        "apikey": target.service_role_key,
        "Authorization": f"Bearer {target.service_role_key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    try:
        response = requests.post(
            f"{target.base_url}/rest/v1/{table}",
            headers=headers,
            json=data,
            timeout=(5, 30),
        )
    except requests.RequestException as error:
        # Exception strings can contain endpoint details; keep operator output safe.
        raise RuntimeError(f"The {table} seed request failed before a response was received.") from error

    if response.status_code not in (201, 204):
        # Do not print the response body; it can contain database details or user data.
        raise RuntimeError(f"The {table} seed request was rejected with HTTP {response.status_code}.")

    count = len(data) if isinstance(data, list) else 1
    print(f"Seeded {count} record(s) into {table}.")


def chunks(values: Iterable[dict], size: int) -> Iterable[list[dict]]:
    batch: list[dict] = []
    for value in values:
        batch.append(value)
        if len(batch) == size:
            yield batch
            batch = []
    if batch:
        yield batch


def seed_database(target: SeedTarget) -> None:
    # This is intentionally legacy demo data, never a production content pipeline.
    languages = [
        {"id": "spanish", "name": "Spanish", "code": "es"},
        {"id": "english", "name": "English", "code": "en"},
        {"id": "french", "name": "French", "code": "fr"},
    ]
    units = [
        {
            "id": "es_unit_1",
            "language_id": "spanish",
            "title": "Basic Survival Kit",
            "description": "Greetings and essentials.",
            "order_index": 1,
        }
    ]
    lessons = [
        {
            "id": "es_u1_l1",
            "unit_id": "es_unit_1",
            "title": "Greetings & Welcomes",
            "description": "Hello and goodbye.",
            "order_index": 1,
        },
        {
            "id": "es_u1_l2",
            "unit_id": "es_unit_1",
            "title": "Essential Needs",
            "description": "Water and bathroom.",
            "order_index": 2,
        },
    ]
    flashcards = (
        {
            "id": str(uuid.uuid4()),
            "lesson_id": "es_u1_l1",
            "front_text": f"Hola {index}",
            "back_text": f"Hello {index}",
            "context_sentence": f"Hola {index}, ¿cómo estás?",
        }
        for index in range(1, 1001)
    )

    insert_data(target, "languages", languages)
    insert_data(target, "units", units)
    insert_data(target, "lessons", lessons)
    for batch in chunks(flashcards, 100):
        insert_data(target, "flashcards", batch)


def parse_arguments(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Seed only a disposable local or staging Spark Lingo database.")
    parser.add_argument("--environment", choices=("local", "staging"), required=True)
    parser.add_argument("--url", help="Non-secret Supabase base URL; otherwise use SPARK_LINGO_SEED_URL.")
    parser.add_argument(
        "--project-ref",
        help="Required only for staging; it must match SPARK_LINGO_STAGING_PROJECT_REF.",
    )
    parser.add_argument("--apply", action="store_true", help="Send seed writes after all target checks pass.")
    parser.add_argument(
        "--confirm-target",
        help="Required with --apply: local-seed or staging-seed, matching --environment.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_arguments(argv)
    try:
        target = configured_target(args)
        if not args.apply:
            print("Dry run passed. No database request was sent; add --apply and the matching confirmation to seed.")
            return 0
        if args.confirm_target != f"{target.environment}-seed":
            raise ConfigurationError("--apply requires the exact matching --confirm-target value.")
        seed_database(target)
    except (ConfigurationError, RuntimeError) as error:
        print(f"Refusing to seed: {error}", file=sys.stderr)
        return 2

    print("Database seed completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
