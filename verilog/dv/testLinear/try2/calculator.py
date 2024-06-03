# Open the equation file
with open('equation.txt', 'r') as file:
    equation = ''
    
    # Read the equations line by line
    for line in file:
        line = line.strip()
        
        if line.endswith('+') or line.endswith('-'):
            # Accumulate the equation if it continues to the next line
            equation += line
        else:
            # Complete equation found
            equation += line
            
            # Evaluate the equation
            try:
                result = eval(equation)
                print(f"The result of the equation is: {result}")
            except (SyntaxError, ZeroDivisionError, NameError, TypeError, ValueError):
                print(f"Invalid equation: {equation}")
            
            # Reset the equation for the next one
            equation = ''
