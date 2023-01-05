'''
This script saves each topic in a bagfile as a csv.
Accepts inputfilename with full path and output folder path.
'''
import rosbag
import sys
import csv
import time
import string
import os  # for file management make directory
import shutil  # for file management, copy file
import argparse


def initialize(cargs):
    listOfBagFiles = [args.inputPath]
    bagNamePath = '/' + \
        args.inputPath.split(
            '/')[len(args.inputPath.split('/'))-1].split('.bag')[0]
    numberOfFiles = "1"
    count = 0
    for bagFile in listOfBagFiles:
        count += 1
        print("reading file " + str(count) +
              " of  " + numberOfFiles + ": " + bagFile)
    # print(args.inputPath)
        # access bag

        bag = rosbag.Bag(bagFile)
        bagContents = bag.read_messages()
        bagName = bag.filename

        if os.path.exists(args.outputPath + bagNamePath):
            continue
        else:
            os.mkdir(args.outputPath + bagNamePath)

        folder = args.outputPath + bagNamePath

        # get list of topics from the bag
        listOfTopics = []
        for topic, msg, t in bagContents:
            if topic not in listOfTopics:
                listOfTopics.append(topic)

        for topicName in listOfTopics:
            # Create a new CSV file for each topic
            filename = folder + '/' + \
                topicName.replace('/', '_slash_') + '.csv'
            with open(filename, 'w+') as csvfile:
                filewriter = csv.writer(csvfile, delimiter=',')
                firstIteration = True  # allows header row
                # for each instant in time that has data for topicName
                for subtopic, msg, t in bag.read_messages(topicName):
                    # parse data from this instant, which is of the form of multiple lines of "Name: value\n"
                    # - put it in the form of a list of 2-element lists
                    msgString = str(msg)
                    msgList = msgString.split('\n')
                    instantaneousListOfData = []
                    for nameValuePair in msgList:
                        splitPair = nameValuePair.split(':')
                        for i in range(len(splitPair)):  # should be 0 to 1
                            splitPair[i] = splitPair[i].strip()
                        instantaneousListOfData.append(splitPair)
                    # write the first row from the first element of each pair
                    if firstIteration:  # header
                        headers = ["rosbagTimestamp"]  # first column header
                        for pair in instantaneousListOfData:
                            headers.append(pair[0])
                        filewriter.writerow(headers)
                        firstIteration = False
                    # write the value from each pair to the file
                    # first column will have rosbag timestamp
                    values = [str(t)]
                    for pair in instantaneousListOfData:
                        if len(pair) > 1:
                            values.append(pair[1])
                    filewriter.writerow(values)
        bag.close()
    print("Done extracting all topics into respectice csv files")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputPath", "-ipDir",
                        help="Set the input file path")
    parser.add_argument("--outputPath", "-opDir",
                        help="Set the input file path")
    args = parser.parse_args()
    initialize(args)
