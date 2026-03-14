import os
from PIL import Image, ImageDraw

def create_logo(size=512):
    img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw teal circle
    circle_color = (37, 124, 118, 255) # Match #257C76
    margin = int(size * 0.05)
    draw.ellipse((margin, margin, size-margin, size-margin), fill=circle_color)
    
    # Draw white house
    house_color = (255, 255, 255, 255)
    center = size // 2
    
    # Roof (triangle)
    roof_width = int(size * 0.5)
    roof_height = int(size * 0.22)
    roof_top = int(size * 0.28)
    
    roof_points = [
        (center, roof_top), # top
        (center - roof_width//2, roof_top + roof_height), # bottom left
        (center + roof_width//2, roof_top + roof_height)  # bottom right
    ]
    draw.polygon(roof_points, fill=house_color)
    
    # Body (rectangle)
    body_width = int(size * 0.35)
    body_height = int(size * 0.22)
    body_top = roof_top + roof_height
    
    body_left = center - body_width//2
    body_right = center + body_width//2
    body_bottom = body_top + body_height
    
    draw.rectangle([body_left, body_top, body_right, body_bottom], fill=house_color)
    
    # Door
    door_width = int(size * 0.08)
    door_height = int(size * 0.1)
    door_left = center - door_width//2
    door_right = center + door_width//2
    door_bottom = body_bottom
    door_top = door_bottom - door_height
    
    draw.rectangle([door_left, door_top, door_right, door_bottom], fill=circle_color)
    
    output_path = "D:/kuliah/semester 4/WPWA/Mobile/rumah_mobile/assets/logo.png"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Saved {output_path}")

create_logo()
