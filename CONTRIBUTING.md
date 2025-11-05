# Contributing to GCC Real Estate Analytics

Thank you for your interest in contributing to this project! Whether you're fixing bugs, adding features, improving documentation, or suggesting enhancements, your contributions are welcome.

---

## 📋 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How to Contribute](#how-to-contribute)
4. [Development Workflow](#development-workflow)
5. [SQL Style Guidelines](#sql-style-guidelines)
6. [Testing Requirements](#testing-requirements)
7. [Documentation Standards](#documentation-standards)
8. [Pull Request Process](#pull-request-process)
9. [Reporting Issues](#reporting-issues)

---

## Code of Conduct

This project follows a simple code of conduct:

- **Be respectful** and professional in all communications
- **Be collaborative** and open to feedback
- **Be constructive** when providing criticism
- **Be patient** with beginners and those learning

---

## Getting Started

### Prerequisites

- PostgreSQL 13+ installed locally
- Git
- Basic SQL knowledge
- Familiarity with GitHub workflows

### Fork and Clone

1. **Fork** this repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/your-username/gulf-sql-portfolio.git
   cd gulf-sql-portfolio
   ```
3. **Add upstream** remote:
   ```bash
   git remote add upstream https://github.com/original-owner/gulf-sql-portfolio.git
   ```

### Set Up Development Environment

1. Create local PostgreSQL database:
   ```bash
   createdb gulf_dev
   ```

2. Load data and build warehouse:
   ```bash
   export PGDATABASE=gulf_dev
   bash scripts/psql_load.sh
   # Run all staging and DW scripts
   ```

3. Verify setup:
   ```bash
   bash scripts/run_tests.sh
   # All tests should pass
   ```

---

## How to Contribute

### Types of Contributions Welcome

- 🐛 **Bug fixes**: Fix incorrect queries, broken scripts, or documentation errors
- ✨ **New features**: Add new KPIs, views, or analyses
- 📊 **Performance improvements**: Optimize queries, add indexes
- 📝 **Documentation**: Improve README, add examples, clarify instructions
- ✅ **Testing**: Add test cases, improve test coverage
- 🎨 **Code quality**: Refactor for clarity, consistency, or maintainability

### What We're Looking For

**High Priority:**
- Additional real-world KPIs (e.g., property liquidity, developer market share)
- Power BI dashboard templates or mockups
- Performance benchmarks and optimization opportunities
- Extended CPI analysis with Dubai-specific economic indicators
- Integration with additional GCC real estate data sources

**Medium Priority:**
- Improved test coverage (target: 50+ tests)
- Data quality monitoring scripts
- Automated data refresh patterns
- Deployment automation (Docker, Terraform)

**Always Welcome:**
- Documentation improvements
- Bug reports
- Feature suggestions
- Use case examples

---

## Development Workflow

### 1. Create a Feature Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
```

**Branch naming conventions:**
- `feature/` for new features (e.g., `feature/add-liquidity-kpi`)
- `fix/` for bug fixes (e.g., `fix/correct-price-calculation`)
- `docs/` for documentation (e.g., `docs/update-deployment-guide`)
- `test/` for test additions (e.g., `test/add-dimension-tests`)
- `perf/` for performance (e.g., `perf/optimize-leaderboard-query`)

### 2. Make Your Changes

- Follow the [SQL Style Guide](docs/sql_style_guide.md)
- Add comments explaining complex logic
- Update relevant documentation
- Add tests for new functionality

### 3. Test Your Changes

```bash
# Run SQL scripts manually
psql -f sql/your_new_file.sql

# Run full test suite
bash scripts/run_tests.sh

# Check for SQL linting issues (if sqlfluff installed)
sqlfluff lint sql/your_new_file.sql --dialect postgres
```

### 4. Commit Your Changes

```bash
git add sql/your_new_file.sql tests/pgtap/your_new_test.sql
git commit -m "feat: Add liquidity KPI calculation

- Calculate days on market for each property segment
- Add percentile analysis for time-to-sale
- Include test cases for edge conditions"
```

**Commit message format:**
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `test:` for test additions
- `perf:` for performance improvements
- `refactor:` for code refactoring
- `style:` for formatting changes

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## SQL Style Guidelines

Please follow our [SQL Style Guide](docs/sql_style_guide.md). Key points:

### Naming
- Tables: `lowercase_with_underscores`, prefixed (`dim_`, `fact_`, `stg_`, `mv_`, `v_`)
- Columns: `lowercase_with_underscores`
- Booleans: `is_`, `has_`, `can_` prefix
- Aliases: Consistent abbreviations (`dd`, `ft`, `st`)

### Formatting
- **2 spaces** for indentation
- **Lowercase SQL keywords**
- **One column per line** in SELECT
- **Commas at start of line**
- **Use CTEs** over subqueries

### Best Practices
- Always use explicit column names (no `SELECT *`)
- Use `NULLIF` for division
- Use `IS NOT DISTINCT FROM` for NULL-safe joins
- Make scripts idempotent (`IF NOT EXISTS`, `IF EXISTS`)
- Run `ANALYZE` after large data changes

**Example:**
```sql
-- Good style
WITH monthly_data AS (
    SELECT
        date_trunc('month', txn_date)::date AS month_start
        , SUM(trans_value) AS total_value
        , COUNT(*) AS txn_count
    FROM stg.dld_transactions
    WHERE trans_value > 0
      AND actual_area > 0
    GROUP BY 1
)
SELECT
    month_start
    , total_value
    , txn_count
FROM monthly_data
ORDER BY month_start DESC;
```

---

## Testing Requirements

### All Code Changes Must Include Tests

- **New KPI**: Add query test in `tests/pgtap/test_kpis.sql`
- **New dimension/fact table**: Add structure test in `tests/pgtap/test_structures.sql`
- **Data transformation**: Add data quality test in `tests/pgtap/test_data_quality.sql`

### Writing pgTAP Tests

```sql
-- Test structure
SELECT has_table('dw', 'your_new_table', 'Table exists');

-- Test data quality
SELECT ok(
    (SELECT COUNT(*) FROM dw.your_table WHERE key_col IS NULL) = 0,
    'No NULL values in key column'
);

-- Test calculation
SELECT ok(
    (SELECT COUNT(*) FROM dw.your_table WHERE calc_col < 0) = 0,
    'No negative calculated values'
);
```

### Running Tests

```bash
# Run all tests
bash scripts/run_tests.sh

# Run specific test file
psql -f tests/pgtap/test_your_new_test.sql
```

All tests must pass before PR can be merged.

---

## Documentation Standards

### Update Documentation When You:

- Add new SQL files → Update README structure section
- Add new KPIs → Update `docs/kpi_definitions.md`
- Change schema → Update `docs/data_dictionary.md` and `docs/erd.md`
- Modify setup → Update README Getting Started section
- Add new materialized views → Update `docs/power_bi_notes.md`

### Documentation Format

- Use **Markdown** for all documentation
- Include **code examples** for complex concepts
- Add **visual diagrams** where helpful (Mermaid or ASCII art)
- Keep language **clear and professional**
- Use **British English** spelling for consistency

---

## Pull Request Process

### Before Submitting

- [ ] Code follows [SQL Style Guide](docs/sql_style_guide.md)
- [ ] All tests pass (`bash scripts/run_tests.sh`)
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] Commit messages are clear and descriptive
- [ ] No merge conflicts with `main`

### PR Template

When you create a PR, include:

```markdown
## Description
[Brief description of what this PR does]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Performance improvement
- [ ] Documentation update
- [ ] Test addition

## Changes Made
- [List specific changes]
- [Include file names]

## Testing
- [ ] All existing tests pass
- [ ] New tests added (if applicable)
- [ ] Manually tested with query results

## Documentation
- [ ] README updated (if needed)
- [ ] Relevant docs updated (if needed)

## Screenshots (if applicable)
[Add query results, EXPLAIN plans, or dashboard mockups]
```

### Review Process

1. **Automated CI** runs on every PR (GitHub Actions)
2. **Manual review** by project maintainer(s)
3. **Feedback** provided as PR comments
4. **Revisions** made if requested
5. **Approval** and merge when ready

**Expected timeline:** 2-5 business days for initial review.

---

## Reporting Issues

### Bug Reports

Use the GitHub issue template and include:

- **Description**: What went wrong?
- **Steps to reproduce**: How can we see the bug?
- **Expected behavior**: What should have happened?
- **Actual behavior**: What actually happened?
- **Environment**: PostgreSQL version, OS, etc.
- **Error messages**: Full error text and stack traces
- **SQL query** (if applicable)

### Feature Requests

Include:

- **Problem statement**: What need does this address?
- **Proposed solution**: How would you solve it?
- **Alternatives considered**: Other approaches?
- **Examples**: Similar features in other projects?
- **Value**: Who benefits and how?

### Questions

- Check existing **documentation** first
- Search **closed issues** for similar questions
- Ask in **GitHub Discussions** for general questions
- Open an **issue** for project-specific questions

---

## Recognition

Contributors will be:

- Listed in project `CONTRIBUTORS.md` (if we create one)
- Credited in release notes for significant contributions
- Given public thanks in PR merge comments

---

## Questions?

- **Documentation**: Check `docs/` folder first
- **Issues**: Open a GitHub issue
- **Contact**: See main README for contact information

---

**Thank you for contributing to GCC Real Estate Analytics!** 🎉

Your time and effort help make this project better for everyone.
