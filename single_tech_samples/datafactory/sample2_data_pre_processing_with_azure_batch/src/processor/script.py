import sys

from datetime import datetime

def initialize():
    
    print("Hi there Code begin!")
    
    try:
    
        source_file = sys.argv[1]
        print("Step 1")

        input_file = open(source_file, "r") 
        print("Step 2")
        num_lines = sum(1 for line in input_file)
        target_file = sys.argv[2]
        
        identifier = datetime.now().strftime("%Y_%m_%d-%I_%M_%S_%p")
        target_file = target_file+"/LC_"+identifier +"__output.txt"
        
        print("Step 3")

        output_file= open(target_file,'w')
        
        print("Step 4")
        output_file.write("The file has "+str(num_lines)+" number of lines count.")
        output_file.close()
        input_file.close()
        print("Success : Output processed!")

    except Exception as e:
        print("Failure Occured!")
        print(e)
      
if __name__ == '__main__':
    initialize()