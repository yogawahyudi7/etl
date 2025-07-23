# Documentation for Debugging and Optimization Scripts

## Overview

This folder contains scripts that help with debugging and optimizing the ETL pipeline. These tools generate test data and optimize data processing for large datasets.

## Generate Data Script (`generate_data.py`)

This script generates sample data that can be used for testing and debugging the ETL pipeline without relying on actual production data.

### Features:
- Generates sample data with the same structure as production data
- Controls the number of rows generated
- Produces data with realistic distribution

### Usage:
```bash
python generate_data.py --rows 10000
```

## Optimize Script (`optimize_script.py`)

This script demonstrates optimization techniques for efficiently processing large data files using chunking to reduce memory usage.

### Features:
- Processes large CSV files in smaller chunks
- Performs filtering and aggregation efficiently
- Significantly reduces memory usage compared to loading the entire file at once

### Usage:
```bash
python optimize_script.py
```

## Optimization Recommendations

Here are key recommendations for optimizing ETL pipeline performance:

1. Use chunking techniques for large files (>100MB)
2. Implement connection pooling for database connections
3. Use parallelization for independent data transformations
4. Optimize SQL queries with appropriate indexes
5. Enable proper logging for easier debugging

**IMPORTANT:** When running optimization scripts with large datasets, ensure sufficient disk space and monitor memory usage.
