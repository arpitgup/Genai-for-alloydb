# Use the official Python image as the base image
FROM python:3.9

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements.txt file to the container
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code to the container
COPY . /app

# Set environment variables, if needed (e.g., for Flask to run in production mode)
#ENV FLASK_ENV=production

# Expose the port that the Flask app will be running on (change it to the appropriate port your app uses)
EXPOSE 5000

# Start the Flask app
CMD ["python", "alloydb.py"]
