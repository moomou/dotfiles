import csv


def csv_2_lines(filename, delimiter=',', quotechar='"'):
    with open(filename) as csvfile:
        reader = csv.reader(
            csvfile,
            delimiter=delimiter,
            quotechar=quotechar,
            quoting=csv.QUOTE_ALL,
            skipinitialspace=True)
        for row in reader:
            yield row
