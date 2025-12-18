#!/usr/bin/env python3.12
"""Convert linter statistics from raw text files to structured JSON format.

This script reads raw output from flake8, ruff, and mypy linters and
converts them to a standardized JSON format with consistent structure:
    {
        "linters": {
            "flake8": [{"linter": "flake8", "count": int, "code": str, "description": str}, ...],
            "ruff": [...],
            "mypy": [...]
        }
    }

Each entry includes:
    - linter: Name of the linter (flake8, ruff, or mypy)
    - count: Number of occurrences of this error
    - code: Error code (e.g., ANN001, no-untyped-def)
    - description: Human-readable description of the error

Usage:
    linter_stats_to_json.py -o <output_dir>
    linter_stats_to_json.py <raw_dir> <output_json>  (legacy)
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

# Mypy error code descriptions
MYPY_DESCRIPTIONS = {
    'no-untyped-def': 'Function is missing a type annotation',
    'attr-defined': 'Attribute does not exist on type',
    'arg-type': 'Argument has incompatible type',
    'import-not-found': 'Cannot find implementation or library stub',
    'var-annotated': 'Variable needs type annotation',
    'union-attr': "Item 'None' of 'Optional[...]' has no attribute",
    'import-untyped': 'Import is not typed or missing type hints',
    'assignment': 'Incompatible types in assignment',
    'call-overload': 'No overload variant matches argument types',
    'return-value': 'Incompatible return value type',
    'type-arg': 'Type argument is incompatible',
    'misc': 'Miscellaneous type error',
}


def parse_line_with_count_code_desc(line: str, linter_name: str, separator: str = None) -> dict[str, Any]:
    """Parse a line with format: count separator code separator description

    Args:
        line: Line to parse
        linter_name: Linter name (e.g., 'flake8', 'ruff', 'mypy')
        separator: Separator character (None for whitespace, '\t' for tab)

    Returns:
        Dictionary with linter, count, code, and description
    """
    line = line.strip()
    if not line:
        return None

    if separator:
        parts = line.split(separator)
    else:
        parts = line.split(None, 2)  # Split on whitespace, max 3 parts

    if len(parts) < 2:
        return None

    count = parts[0].strip()
    code = parts[1].strip()
    description = parts[2].strip() if len(parts) > 2 else '-'

    try:
        return {
            'linter': linter_name,
            'count': int(count),
            'code': code,
            'description': description
        }
    except ValueError:
        return None


def parse_flake8(file_path: Path) -> list[dict[str, Any]]:
    """Parse flake8 statistics file.

    Format: "count code description" (space-separated)
    Example: "124   ANN001 Missing type annotation for function argument"

    Args:
        file_path: Path to flake8 stats file

    Returns:
        List of linter error dictionaries
    """
    linter_errors = []

    if not file_path.exists():
        return linter_errors

    with open(file_path) as f:
        for line in f:
            linter_error = parse_line_with_count_code_desc(line, linter_name='flake8', separator=None)
            if linter_error:
                linter_errors.append(linter_error)

    return linter_errors


def parse_ruff(file_path: Path) -> list[dict[str, Any]]:
    """Parse ruff statistics file.

    Format: "count\tcode\tdescription" (tab-separated)
    Example: "124\tANN001\tMissing type annotation for function argument"

    Args:
        file_path: Path to ruff stats file

    Returns:
        List of linter error dictionaries
    """
    linter_errors = []

    if not file_path.exists():
        return linter_errors

    with open(file_path) as f:
        for line in f:
            linter_error = parse_line_with_count_code_desc(line, linter_name='ruff', separator='\t')
            if linter_error:
                linter_errors.append(linter_error)

    return linter_errors


def parse_mypy(file_path: Path) -> list[dict[str, Any]]:
    """Parse mypy statistics file.

    Format: "count code" (space-separated, no description in file)
    Example: "82 no-untyped-def"

    Args:
        file_path: Path to mypy stats file

    Returns:
        List of linter error dictionaries with descriptions added from MYPY_DESCRIPTIONS
    """
    linter_errors = []

    if not file_path.exists():
        return linter_errors

    with open(file_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            parts = line.split(None, 1)  # Split into count and code
            if len(parts) == 2:
                count_str, error_code = parts
                try:
                    error_count = int(count_str.strip())
                    error_code = error_code.strip()
                    error_description = MYPY_DESCRIPTIONS.get(error_code, '-')

                    linter_errors.append({
                        'linter': 'mypy',
                        'count': error_count,
                        'code': error_code,
                        'description': error_description
                    })
                except ValueError:
                    continue

    return linter_errors


def write_json(data: dict[str, Any], output_path: Path) -> None:
    """Write data to JSON file with pretty formatting.

    Args:
        data: Data to write
        output_path: Path to output JSON file
    """
    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)


def convert_stats_to_json(raw_dir: Path, output_json: Path) -> None:
    """Convert all linter stats to a single JSON file.

    Args:
        raw_dir: Directory containing raw stats files
        output_json: Path to output JSON file
    """
    # Initialize data structure
    linter_data = {
        'linters': {
            'flake8': [],
            'ruff': [],
            'mypy': []
        }
    }

    # Parse each linter's output
    linter_data['linters']['flake8'] = parse_flake8(raw_dir / 'flake8_stats_raw.txt')
    linter_data['linters']['ruff'] = parse_ruff(raw_dir / 'ruff_stats_raw.txt')
    linter_data['linters']['mypy'] = parse_mypy(raw_dir / 'mypy_stats_raw.txt')

    # Write to JSON
    write_json(linter_data, output_json)

    # Print summary
    total_flake8 = sum(e['count'] for e in linter_data['linters']['flake8'])
    total_ruff = sum(e['count'] for e in linter_data['linters']['ruff'])
    total_mypy = sum(e['count'] for e in linter_data['linters']['mypy'])

    print('Converted statistics to JSON:')
    print(f"  - Flake8: {len(linter_data['linters']['flake8'])} error types, {total_flake8} total errors")
    print(f"  - Ruff:   {len(linter_data['linters']['ruff'])} error types, {total_ruff} total errors")
    print(f"  - Mypy:   {len(linter_data['linters']['mypy'])} error types, {total_mypy} total errors")
    print(f'  - Output: {output_json}')


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Convert linter raw stats to JSON format.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -o /tmp/linter_report-myproject
  %(prog)s -o ~/reports/project_linter_stats

Legacy usage (deprecated):
  %(prog)s <raw_dir> <output_json>
        """
    )

    parser.add_argument(
        '-o', '--output',
        type=str,
        metavar='DIR',
        help='Output directory (reads from DIR/*.txt, writes to DIR/linter_stats.json)'
    )

    # Try new format first
    if '-o' in sys.argv or '--output' in sys.argv:
        args = parser.parse_args()
        output_dir = Path(args.output).expanduser()
        raw_dir = output_dir
        output_json = output_dir / 'linter_stats.json'
    # Legacy format: linter_stats_to_json.py <raw_dir> <output_json>
    elif len(sys.argv) == 3:
        raw_dir = Path(sys.argv[1]).expanduser()
        output_json = Path(sys.argv[2]).expanduser()
    else:
        parser.print_help()
        sys.exit(1)

    if not raw_dir.exists():
        print(f'Error: Directory does not exist: {raw_dir}', file=sys.stderr)
        sys.exit(1)

    try:
        convert_stats_to_json(raw_dir, output_json)
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
