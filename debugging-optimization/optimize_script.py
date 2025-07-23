import pandas as pd

# Initialize an empty DataFrame to store aggregated results
result = pd.DataFrame()

# Process the file in chunks
chunk_size = 1_000_000  # Process 1 million rows at a time
for chunk in pd.read_csv("large_file.csv", chunksize=chunk_size):
    # Filter rows where 'price' > 100
    filtered_chunk = chunk[chunk["price"] > 100]
    
    # Group and aggregate within the chunk
    aggregated_chunk = filtered_chunk.groupby("category").sum()
    
    # Incrementally update the result
    if result.empty:
        result = aggregated_chunk
    else:
        result = result.add(aggregated_chunk, fill_value=0)

# Save the final aggregated result to a CSV file
result.to_csv("output.csv")
