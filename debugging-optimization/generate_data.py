import pandas as pd
import numpy as np

# Generate 10 million rows of data
rows = 10_000_000
data = {
    "category": np.random.choice(["A", "B", "C", "D", "E"], size=rows),
    "price": np.random.uniform(1, 1000, size=rows),
    "quantity": np.random.randint(1, 100, size=rows)
}

# Save to CSV
df = pd.DataFrame(data)
df.to_csv("large_file.csv", index=False)
