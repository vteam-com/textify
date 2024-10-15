import cv2
import numpy as np
import glob
import os

# Step 1: Delete any existing letter files
for filename in glob.glob('letter_*.png'):
    os.remove(filename)

# Load the image
image = cv2.imread('test_image3.png')

# Convert to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Use adaptive thresholding
binary = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                               cv2.THRESH_BINARY_INV, 11, 2)

# Define a kernel for morphological operations

# Morphological operations to separate touching letters
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (4, 7))
eroded = cv2.morphologyEx(binary, cv2.MORPH_ERODE, kernel, iterations=1)
cv2.imwrite(f'tmp_eroded.png', eroded)
kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (6, 9))
dilated = cv2.morphologyEx(eroded, cv2.MORPH_DILATE, kernel2, iterations=1)
cv2.imwrite(f'tmp_dilated.png', dilated)

# Find contours
contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Sort contours from left to right
contours = sorted(contours, key=lambda c: cv2.boundingRect(c)[0])

# Isolate each letter
letter_images = []
for contour in contours:
    x, y, w, h = cv2.boundingRect(contour)
    letter_image = image[y:y+h, x:x+w]
    letter_images.append(letter_image)

# Save or display each letter image
for i, letter in enumerate(letter_images):
    cv2.imwrite(f'letter_{i}.png', letter)

# Optionally, display the images
# for letter in letter_images:
#     cv2.imshow('Letter', letter)
#     cv2.waitKey(0)
# cv2.destroyAllWindows()