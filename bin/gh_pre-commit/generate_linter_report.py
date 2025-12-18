#!/usr/bin/env python3.12
"""Generate markdown reports from linter statistics JSON data.

This script:
1. Cleans the output directory
2. Runs the data collection script to generate JSON
3. Creates markdown reports from the JSON

Output files:
    <project>-linter_report.md           Combined linter report
    <project>-linter_low_risk_report.md  Low risk errors report

Usage:
    generate_reports.py -p <project_path> -o <output_dir>
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

SEPARATOR = '-' * 80


def format_path_for_display(path: Path | str) -> str:
    """Replace home directory in path with ~ for display.

    Args:
        path: Path to format (Path object or string)

    Returns:
        Formatted path string with home directory replaced by ~
    """
    path_str = str(path)
    home_dir = str(Path.home())

    if path_str.startswith(home_dir):
        return path_str.replace(home_dir, '~', 1)

    return path_str


# Low risk fix patterns - these help identify which errors are low risk to fix
# Based on error code patterns, not specific hardcoded codes
LOW_RISK_FIX_CATEGORIES = {
    'Formatting/Style': {
        'patterns': ['T201', 'D205', 'D415', 'D200', 'E203', 'E261', 'E127'],
        'risk': 'Very Low',
        'fix_type': 'Formatting/style changes'
    },
    'Dead/Commented Code': {
        'patterns': ['ERA001', 'E800'],
        'risk': 'Very Low',
        'fix_type': 'Remove commented code'
    },
    'Simple Refactoring': {
        'patterns': ['SIM201', 'SIM108', 'PIE810', 'PERF401', 'RET504', 'R504'],
        'risk': 'Low',
        'fix_type': 'Simple logic improvements'
    },
}


def load_json_data(json_path: Path) -> dict[str, Any]:
    """Load linter statistics from JSON file."""
    with open(json_path) as f:
        return json.load(f)


def create_individual_linter_table(linter_name: str, linter_errors: list[dict[str, Any]]) -> str:
    """Create markdown table for a single linter.

    Args:
        linter_name: Name of the linter (capitalized for display)
        linter_errors: List of error dictionaries from JSON

    Returns:
        Markdown formatted table
    """
    if not linter_errors:
        return f'## {linter_name}\n\nNo errors found.\n\n'

    # Sort by count descending
    sorted_errors = sorted(linter_errors, key=lambda x: x['count'], reverse=True)

    output = f'## {linter_name}\n\n'
    output += '| Hook | Error Code | Description | Count |\n'
    output += '|------|------------|-------------|------:|\n'

    total_count = 0
    for error in sorted_errors:
        linter = error['linter']
        code = error['code']
        description = error['description']
        count = error['count']
        total_count += count
        output += f'| {linter} | {code} | {description} | {count} |\n'

    output += f'\n**Total: {total_count} errors**\n\n'
    return output


def create_combined_report(linter_data: dict[str, Any]) -> str:
    """Generate the combined error report from JSON data."""
    report = '# Pre-commit Error Statistics\n\n'

    # Individual linter tables (sorted by count descending)
    report += create_individual_linter_table('Ruff', linter_data['linters']['ruff'])
    report += f'{SEPARATOR}\n\n'
    report += create_individual_linter_table('Flake8', linter_data['linters']['flake8'])
    report += f'{SEPARATOR}\n\n'
    report += create_individual_linter_table('Mypy', linter_data['linters']['mypy'])

    return report


def categorize_error_for_low_risk_fixes(error_code: str) -> str:
    """Categorize an error code into a low risk fix category.

    Args:
        error_code: The error code to categorize

    Returns:
        Category name or None if not a low risk fix
    """
    for category, info in LOW_RISK_FIX_CATEGORIES.items():
        if error_code in info['patterns']:
            return category
    return None


def create_low_risk_fixes_report(linter_data: dict[str, Any]) -> str:
    """Generate the low risk fixes report from JSON data."""
    # Collect all errors that match low risk fix patterns
    categorized_errors = {category: [] for category in LOW_RISK_FIX_CATEGORIES}

    # Process all linters
    for linter_name in ['ruff', 'flake8']:  # mypy errors typically need more analysis
        for error in linter_data['linters'].get(linter_name, []):
            category = categorize_error_for_low_risk_fixes(error['code'])
            if category:
                categorized_errors[category].append(error)

    report = '# Low Risk Errors\n\n'

    # Generate tables for each category
    for category in LOW_RISK_FIX_CATEGORIES:
        errors = categorized_errors[category]

        if not errors:
            continue

        report += f'## {category}\n\n'
        report += '| Error Code | Description | Linter | Count |\n'
        report += '|------------|-------------|--------|------:|\n'

        # Sort by count (highest to lowest)
        sorted_errors = sorted(errors, key=lambda x: x['count'], reverse=True)

        for error in sorted_errors:
            code = error['code']
            description = error['description']
            linter = error['linter']
            count = error['count']
            report += f'| {code} | {description} | {linter} | {count} |\n'

        report += f'\n{SEPARATOR}\n\n'

    return report


def write_report(report_content: str, output_path: Path) -> None:
    """Write report to file."""
    with open(output_path, 'w') as f:
        f.write(report_content)


def clean_output_directory(output_dir: Path) -> None:
    """Remove all files from the output directory."""
    if output_dir.exists():
        print(f'Cleaning output directory: {format_path_for_display(output_dir)}')
        for file in output_dir.glob('*'):
            if file.is_file():
                file.unlink()
                print(f'  Removed: {file.name}')
    else:
        output_dir.mkdir(parents=True, exist_ok=True)
        print(f'Created output directory: {format_path_for_display(output_dir)}')


def setup_output_directory(output_dir: Path) -> None:
    """Create output directory.

    Args:
        output_dir: Output directory
    """
    output_dir.mkdir(parents=True, exist_ok=True)


def run_data_collection(project_path: Path, script_dir: Path, output_dir: Path) -> Path:
    """Run the collect_linter_stats.sh script to collect data and create JSON.

    Args:
        project_path: Path to the git project to analyze
        script_dir: Directory containing the scripts
        output_dir: Base output directory

    Returns:
        Path to the generated JSON file

    Raises:
        RuntimeError: If the data collection fails
    """
    stats_script = script_dir / 'collect_linter_stats.sh'

    if not stats_script.exists():
        raise RuntimeError(f'Data collection script not found: {format_path_for_display(stats_script)}')

    print(f'\nRunning data collection for project: {format_path_for_display(project_path)}')
    print(f'Using script: {format_path_for_display(stats_script)}')
    print(f'Output directory: {format_path_for_display(output_dir)}')
    print('-' * 80)

    # Build command: script -p project_path -o output_dir
    cmd = [str(stats_script), '-p', str(project_path), '-o', str(output_dir)]

    # Run the bash script
    try:
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True
        )

        # Print the output
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)

    except subprocess.CalledProcessError as e:
        print(f'\nError: Data collection failed with exit code {e.returncode}', file=sys.stderr)
        if e.stdout:
            print('STDOUT:', e.stdout, file=sys.stderr)
        if e.stderr:
            print('STDERR:', e.stderr, file=sys.stderr)
        raise RuntimeError(f'Failed to run data collection script: {e}')

    # Return the expected JSON path
    json_path = output_dir / 'linter_stats.json'

    if not json_path.exists():
        raise RuntimeError(f'Expected JSON file not created: {format_path_for_display(json_path)}')

    return json_path


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Generate linter error reports from a git project.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -p ~/projects/my-python-app
  %(prog)s -p ~/projects/my-python-app -o /tmp/custom_output

Output files:
  <output-dir>/*.txt                              Raw linter stats
  <output-dir>/linter_stats.json                  Combined JSON data
  <output-dir>/<project>-linter_report.md         Combined linter report
  <output-dir>/<project>-linter_low_risk_report.md  Low risk errors

Note: To list files or use other options, run collect_linter_stats.sh directly
        """
    )

    parser.add_argument(
        '-p', '--project',
        type=str,
        required=True,
        metavar='PATH',
        help='Path to the git project to analyze'
    )

    parser.add_argument(
        '-o', '--output',
        type=str,
        metavar='DIR',
        default=None,
        help='Output directory (default: /tmp/linter_report-<project_name>)'
    )

    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_arguments()

    # Expand project path
    project_path = Path(args.project).expanduser()

    # Expand output directory or use default (based on project name)
    if args.output:
        output_dir = Path(args.output).expanduser()
    else:
        project_name = project_path.name
        output_dir = Path(f'/tmp/linter_report-{project_name}')

    # Validate project path
    if not project_path.exists():
        print(f'Error: Project path does not exist: {format_path_for_display(project_path)}', file=sys.stderr)
        sys.exit(1)

    try:
        # Get script directory (where this script is located)
        script_dir = Path(__file__).parent

        # Setup and clean output directory
        setup_output_directory(output_dir)
        clean_output_directory(output_dir)

        # Run data collection to generate JSON
        print('\n' + '=' * 80)
        print('Step 1: Collecting linter data')
        print('=' * 80)
        json_path = run_data_collection(project_path, script_dir, output_dir)

        # Generate reports from JSON
        print('\n' + '=' * 80)
        print('Step 2: Generating markdown reports')
        print('=' * 80)

        linter_data = load_json_data(json_path)

        # Get project name from project path
        project_name = project_path.name

        combined_report = create_combined_report(linter_data)
        low_risk_report = create_low_risk_fixes_report(linter_data)

        combined_path = output_dir / f'{project_name}-linter_report.md'
        low_risk_path = output_dir / f'{project_name}-linter_low_risk_report.md'

        write_report(combined_report, combined_path)
        write_report(low_risk_report, low_risk_path)

        print('\nReports generated successfully:')
        print(f'  - Linter report: {format_path_for_display(combined_path)}')
        print(f'  - Low risk report: {format_path_for_display(low_risk_path)}')
        print(f'  - JSON data: {format_path_for_display(json_path)}')

    except Exception as e:
        print(f'\nError: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
