#!/usr/bin/env python3.12
"""Find pre-commit tool executable paths dynamically.

This module queries the pre-commit SQLite database and .pre-commit-config.yaml
to find the correct executable paths for linters, ensuring the correct Python
version and repository revision are used.
"""
from __future__ import annotations

import os
import sqlite3
import subprocess
from pathlib import Path


def get_precommit_cache_dir() -> Path:
    """Get the pre-commit cache directory path.

    Returns:
        Path to pre-commit cache directory (usually ~/.cache/pre-commit)
    """
    # Check for custom cache directory via environment variables
    if 'PRE_COMMIT_HOME' in os.environ:
        return Path(os.environ['PRE_COMMIT_HOME'])

    if 'XDG_CACHE_HOME' in os.environ:
        return Path(os.environ['XDG_CACHE_HOME']) / 'pre-commit'

    # Default location
    return Path.home() / '.cache' / 'pre-commit'


def is_git_repository(project_path: Path) -> bool:
    """Check if path is a git repository.

    Args:
        project_path: Path to check

    Returns:
        True if path is a git repository, False otherwise
    """
    git_dir = project_path / '.git'
    return git_dir.exists() and git_dir.is_dir()


def get_python_version_from_config(project_path: Path) -> str | None:
    """Extract Python version from .pre-commit-config.yaml.

    Args:
        project_path: Path to git project root

    Returns:
        Python version string (e.g., 'python3.12') or None if not found

    Raises:
        ValueError: If project_path is not a git repository
    """
    if not is_git_repository(project_path):
        raise ValueError(f'Not a git repository: {project_path}')

    config_file = project_path / '.pre-commit-config.yaml'

    if not config_file.exists():
        return None

    try:
        # Use grep to find the python version
        result = subprocess.run(
            ['grep', '-A', '1', 'default_language_version:', str(config_file)],
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode == 0:
            for line in result.stdout.splitlines():
                if 'python:' in line:
                    # Extract version like "python3.12" from "  python: python3.12"
                    version = line.split('python:')[1].strip()
                    return version
    except Exception:
        pass

    return None


def get_tool_version_from_config(project_path: Path, repo_pattern: str) -> str | None:
    """Extract tool version from .pre-commit-config.yaml.

    Args:
        project_path: Path to git project root
        repo_pattern: Pattern to match repo URL (e.g., 'astral-sh/ruff-pre-commit')

    Returns:
        Version string (e.g., 'v0.12.12') or None if not found

    Raises:
        ValueError: If project_path is not a git repository
    """
    if not is_git_repository(project_path):
        raise ValueError(f'Not a git repository: {project_path}')

    config_file = project_path / '.pre-commit-config.yaml'

    if not config_file.exists():
        return None

    try:
        # Use grep to find the repo and version
        result = subprocess.run(
            ['grep', '-A', '3', repo_pattern, str(config_file)],
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode == 0:
            for line in result.stdout.splitlines():
                if 'rev:' in line:
                    # Extract version like "v0.12.12" from "    rev: v0.12.12"
                    version = line.split('rev:')[1].strip()
                    return version
    except Exception:
        pass

    return None


def query_precommit_db(repo_pattern: str, version: str) -> str | None:
    """Query pre-commit SQLite database for repository path.

    Args:
        repo_pattern: Pattern to match in repo URL (e.g., 'ruff-pre-commit')
        version: Version/revision to match

    Returns:
        Path to repository in cache, or None if not found
    """
    db_path = get_precommit_cache_dir() / 'db.db'

    if not db_path.exists():
        return None

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Query for matching repo and version
        query = 'SELECT path FROM repos WHERE repo LIKE ? AND ref = ?'
        cursor.execute(query, (f'%{repo_pattern}%', version))

        results = cursor.fetchall()
        conn.close()

        if results:
            # Return the last match (most recent if multiple)
            return results[-1][0]
    except Exception:
        pass

    return None


def get_tool_path(project_path: Path, repo_pattern: str, tool_name: str) -> str | None:
    """Get full path to a pre-commit tool executable.

    Args:
        project_path: Path to git project root containing .pre-commit-config.yaml
        repo_pattern: Pattern to match repo URL (e.g., 'astral-sh/ruff-pre-commit')
        tool_name: Name of executable (e.g., 'ruff', 'flake8', 'mypy')

    Returns:
        Full path to tool executable, or None if not found

    Raises:
        ValueError: If project_path is not a git repository
    """
    # Validate git repository
    if not is_git_repository(project_path):
        raise ValueError(f'Not a git repository: {project_path}')

    # Get Python version from config
    python_version = get_python_version_from_config(project_path)
    if not python_version:
        return None

    # Get tool version from config
    tool_version = get_tool_version_from_config(project_path, repo_pattern)
    if not tool_version:
        return None

    # Query database for repo path
    # Extract the short pattern from full URL pattern
    if '/' in repo_pattern:
        db_pattern = repo_pattern.split('/')[-1]
    else:
        db_pattern = repo_pattern

    repo_path = query_precommit_db(db_pattern, tool_version)
    if not repo_path:
        return None

    # Construct full path to executable
    full_path = f'{repo_path}/py_env-{python_version}/bin/{tool_name}'

    # Verify it exists
    if os.path.exists(full_path):
        return full_path

    return None


def get_ruff_path(project_path: Path) -> str | None:
    """Get path to ruff executable used by pre-commit.

    Args:
        project_path: Path to git project root

    Returns:
        Full path to ruff executable, or None if not found
    """
    return get_tool_path(project_path, 'astral-sh/ruff-pre-commit', 'ruff')


def get_flake8_path(project_path: Path) -> str | None:
    """Get path to flake8 executable used by pre-commit.

    Args:
        project_path: Path to git project root

    Returns:
        Full path to flake8 executable, or None if not found
    """
    return get_tool_path(project_path, 'pycqa/flake8', 'flake8')


def get_mypy_path(project_path: Path) -> str | None:
    """Get path to mypy executable used by pre-commit.

    Args:
        project_path: Path to git project root

    Returns:
        Full path to mypy executable, or None if not found
    """
    return get_tool_path(project_path, 'pre-commit/mirrors-mypy', 'mypy')


def format_path_for_display(path: Path) -> str:
    """Replace home directory in path with ~ for display.

    Args:
        path: Path to format

    Returns:
        Formatted path string with home directory replaced by ~
    """
    path_str = str(path)
    home_dir = str(Path.home())

    if path_str.startswith(home_dir):
        return path_str.replace(home_dir, '~', 1)

    return path_str


def main():
    """Example usage and testing."""
    import argparse
    import sys

    parser = argparse.ArgumentParser(
        description='Find pre-commit tool executable paths dynamically.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -p ~/projects/my-python-app
  %(prog)s --project ~/projects/my-python-app

Output:
  Displays the full paths to ruff, flake8, and mypy executables
  used by pre-commit for the specified project.
        """
    )

    parser.add_argument(
        '-p', '--project',
        type=str,
        required=True,
        metavar='PATH',
        help='Path to the git project'
    )

    args = parser.parse_args()

    project_path = Path(args.project).expanduser()

    if not project_path.exists():
        print(f'Error: Project path does not exist: {format_path_for_display(project_path)}')
        sys.exit(1)

    if not is_git_repository(project_path):
        print(f'Error: Not a git repository: {format_path_for_display(project_path)}')
        print('       .git directory not found')
        sys.exit(1)

    print(f'Searching for pre-commit tools in: {format_path_for_display(project_path)}\n')

    ruff = get_ruff_path(project_path)
    flake8 = get_flake8_path(project_path)
    mypy = get_mypy_path(project_path)

    print('Found tool paths:')
    if ruff:
        print(f'  RUFF_BIN="{ruff}"')
    if flake8:
        print(f'  FLAKE8_BIN="{flake8}"')
    if mypy:
        print(f'  MYPY_BIN="{mypy}"')

    # Verify they exist
    print('\nVerification:')
    for name, path in [('ruff', ruff), ('flake8', flake8), ('mypy', mypy)]:
        if path and os.path.exists(path):
            print(f'  ✓ {name}: exists')
        elif path:
            print(f"  ✗ {name}: path found but file doesn't exist")
        else:
            print(f'  ✗ {name}: not found')


if __name__ == '__main__':
    main()
