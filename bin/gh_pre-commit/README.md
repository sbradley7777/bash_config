# Pre-commit Linter Report Tools

A collection of scripts to analyze Python projects using pre-commit linters (flake8, ruff, mypy) and generate detailed statistics and reports.

## Overview

These tools help you:
- Run pre-commit linters on your Python projects
- Collect and analyze linter error statistics
- Generate markdown reports for easy review
- Track linting progress over time

## Scripts

### 1. `collect_linter_stats.sh`
Runs pre-commit linters on all git-tracked Python files and collects raw statistics.

**Usage:**
```bash
$ collect_linter_stats.sh -p <project-path> [-o <output-dir>] [-l]
```

**Options:**
- `-p <path>` - Path to git project (required)
- `-o <dir>` - Output directory (default: `/tmp/linter_report-<project_name>`)
- `-l` - List files only (don't run linters)

**Examples:**
```bash
# Analyze a project (outputs to /tmp/linter_report-myproject)
$ collect_linter_stats.sh -p ~/projects/myproject

# Specify custom output directory
$ collect_linter_stats.sh -p ~/projects/myproject -o ~/reports/custom

# List Python files that would be checked (dry run)
$ collect_linter_stats.sh -p ~/projects/myproject -l
```

**What it does:**
1. Discovers pre-commit tool paths from your project's `.pre-commit-config.yaml`
2. Finds all git-tracked Python files
3. Runs flake8, ruff, and mypy
4. Saves raw statistics to text files
5. Converts statistics to JSON format

**Output files:**
- `flake8_stats_raw.txt` - Raw flake8 error counts
- `ruff_stats_raw.txt` - Raw ruff error counts
- `mypy_stats_raw.txt` - Raw mypy error counts
- `linter_stats.json` - Combined JSON data

---

### 2. `linter_stats_to_json.py`
Converts raw linter statistics to structured JSON format.

**Usage:**
```bash
$ linter_stats_to_json.py -o <output-dir>
```

**Options:**
- `-o <dir>` - Output directory (reads `*.txt`, writes `linter_stats.json`)

**Examples:**
```bash
# Convert raw stats to JSON
$ linter_stats_to_json.py -o /tmp/linter_report-myproject

# With custom directory
$ linter_stats_to_json.py -o ~/reports/custom
```

**Note:** This is typically called automatically by `collect_linter_stats.sh`

---

### 3. `generate_linter_report.py`
Generates markdown reports from linter statistics.

**Usage:**
```bash
$ generate_linter_report.py -p <project-path> [-o <output-dir>]
```

**Options:**
- `-p <path>` - Path to git project (required)
- `-o <dir>` - Output directory (default: `/tmp/linter_report-<project_name>`)

**Examples:**
```bash
# Generate reports for a project
$ generate_linter_report.py -p ~/projects/myproject

# With custom output directory
$ generate_linter_report.py -p ~/projects/myproject -o ~/reports/custom
```

**What it does:**
1. Runs `collect_linter_stats.sh` to gather data
2. Generates markdown reports from JSON
3. Creates combined and filtered reports

**Output files:**
- `<project>-linter_report.md` - Combined report with all errors
- `<project>-linter_low_risk_report.md` - Low-risk errors only
- `linter_stats.json` - Raw JSON data
- `*.txt` - Raw linter output

---

### 4. `precommit_tool_finder.py`
Utility to discover pre-commit tool paths dynamically.

**Usage:**
```bash
$ precommit_tool_finder.py -p <project-path>
```

**Examples:**
```bash
# Find tool paths for a project
$ precommit_tool_finder.py -p ~/projects/myproject
```

**What it does:**
- Queries `.pre-commit-config.yaml` for tool versions
- Searches pre-commit cache database
- Returns full paths to linter executables

**Note:** This is typically called automatically by `collect_linter_stats.sh`

---

## Quick Start

### Basic Workflow

**1. Run full analysis and generate reports:**
```bash
$ generate_linter_report.py -p ~/projects/myproject
```

This single command:
- Collects all linter statistics
- Converts to JSON
- Generates markdown reports

**2. View the results:**
```bash
# Combined report (all errors)
$ cat /tmp/linter_report-myproject/myproject-linter_report.md

# Low-risk errors only
$ cat /tmp/linter_report-myproject/myproject-linter_low_risk_report.md
```

**3. Just collect statistics (no reports):**
```bash
$ collect_linter_stats.sh -p ~/projects/myproject
```

---

## Prerequisites

### Required Tools
- **Python 3.12+** - All Python scripts require Python 3.12
- **git** - Project must be a git repository
- **Pre-commit** - Project must have `.pre-commit-config.yaml`

### Pre-commit Linters
Your project should have these hooks configured in `.pre-commit-config.yaml`:
- `ruff` (recommended: astral-sh/ruff-pre-commit)
- `flake8` (recommended: pycqa/flake8)
- `mypy` (recommended: pre-commit/mirrors-mypy)

### Example `.pre-commit-config.yaml`:
```yaml
default_language_version:
  python: python3.12

repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.12.12
    hooks:
      - id: ruff

  - repo: https://github.com/pycqa/flake8
    rev: 7.1.1
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
```

---

## Output Structure

After running the tools, your output directory will contain:

```
/tmp/linter_report-myproject/
├── flake8_stats_raw.txt              # Raw flake8 error counts
├── ruff_stats_raw.txt                # Raw ruff error counts
├── mypy_stats_raw.txt                # Raw mypy error counts
├── linter_stats.json                 # Combined JSON data
├── myproject-linter_report.md        # Combined markdown report
└── myproject-linter_low_risk_report.md  # Low-risk errors report
```

---

## Report Format

### Combined Report
Shows all errors grouped by linter with counts and descriptions.

**Example:**
```markdown
## Ruff

| Hook | Error Code | Description | Count |
|------|------------|-------------|------:|
| ruff | ANN001 | Missing type annotation for function argument | 45 |
| ruff | D205 | 1 blank line required between summary line and description | 23 |

**Total: 68 errors**
```

### Low-Risk Report
Shows only errors that are safe/easy to fix (formatting, style, commented code).

---

## Tips

### Analyzing Multiple Projects
Each project gets its own output directory:
```bash
$ generate_linter_report.py -p ~/projects/project1  # → /tmp/linter_report-project1/
$ generate_linter_report.py -p ~/projects/project2  # → /tmp/linter_report-project2/
```

### Custom Output Location
Use `-o` to specify a different location:
```bash
$ generate_linter_report.py -p ~/projects/myproject -o ~/Documents/reports
```

### Checking What Files Will Be Analyzed
Use the `-l` flag to see which files will be checked without running linters:
```bash
$ collect_linter_stats.sh -p ~/projects/myproject -l
```

### Running Only Data Collection
If you only need raw statistics:
```bash
$ collect_linter_stats.sh -p ~/projects/myproject
```

### Converting Existing Raw Stats
If you have raw stats files and just need JSON:
```bash
$ linter_stats_to_json.py -o /tmp/linter_report-myproject
```

---

## Troubleshooting

### "Error: Not a git repository"
**Solution:** The path must point to a git repository with a `.git` directory.

### "Error: precommit_tool_finder.py not found"
**Solution:** Ensure all scripts are in the same directory.

### "Warning: Using fallback tool paths"
**Solution:** Ensure your project has `.pre-commit-config.yaml` with the required linters configured.

### "Tool paths not found"
**Solution:** Run `pre-commit install` and `pre-commit run` in your project first to cache the tools.

### Empty Statistics Files
**Solution:** Your project may not have Python files or may not have any linter errors.

---

## License

These scripts are part of the bash_config repository.
