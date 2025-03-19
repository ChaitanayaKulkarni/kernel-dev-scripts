class Shape:
    def area(self):
        pass

class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius

    def area(self):
        return 3.14 * self.radius * self.radius

class Rectangle(Shape):
    def __init__(self, length, width):
        self.length = length
        self.width = width

    def area(self):
        return self.length * self.width

class Triangle(Shape):
    def __init__(self, base, height):
        self.base = base
        self.height = height

    def area(self):
        return 0.5 * self.base * self.height

class Test:
    def check(self):
        print("hahahah")

# Function to calculate and print the area of a shape
def print_area(shape):
    print(f"Area of the shape is: {shape.area()}")

# Creating objects of different shapes
shape = Circle(5)
print_area(shape)

shape = Rectangle(4, 6)
print_area(shape)

shape = Triangle(3, 8)
print_area(shape)

shape = Test()
print_area(shape)
