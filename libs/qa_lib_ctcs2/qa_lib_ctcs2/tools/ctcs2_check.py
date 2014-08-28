#!/usr/bin/env python
#
# CTCS2 overall results are stored in test_results file each testcase record
# consists of a line with testcase name and line with result numbers.
#
# testcase_name
# fail succeed count runtime internal_err skipped
#
# HINT: Timeouted testcases have zero count and nonzero runtime.
#

# ============================ IMPORTANT ============================
# Some parts of the code are not written in a best possible way. The
# reason for this is the backwards compatibility with Python 2.4.2 is
# required.
#
# For this very reason no argument parsing library is used.
# ============================ IMPORTANT ============================

import os
import sys

class ResIndexes(object):
    """Indexes of the values from the 'test_results' file."""
    failed = 0
    succeeded = 1
    count = 2
    time = 3
    interr = 4
    skipped = 5

class Result(object):
    """Holds results of a testsuite and the order in which the tests
    were run."""

    def __init__(self, directory = '', results = {}, order = []):
        """Create a result object.

        Provide a 'directory' path to the results or directly use
        'results' and 'order' to initialize."""
        self.file_name = 'test_results'
        if directory:
            results, order = self.read_file(os.path.join(directory,
                                                         self.file_name))
        self.results = results
        self.order = order

    def read_file(self, results_path):
        """Read results from a file."""
        if os.path.exists(results_path):
            try:
                f = open(results_path)
                lines = f.readlines()
            finally:
                f.close()
        else:
            print("Can not open file at %s." % (results_path))
            exit(1)

        lines = [str.strip('\n') for str in lines]
        # Return a dictionary mapping test names and results from the
        # file lines array
        results = dict(zip(lines[::2], lines[1::2]))
        return results, lines[::2]

    def get_results(self):
        return self.results

    def get_order(self):
        return self.order

    def has_test(self, test_name):
        return test_name in self.get_order()

    def get_result(self, test_name):
        return self.get_results()[test_name]

    def __str__(self):
        res = self.get_results()
        out = ''
        for name in self.get_order():
            out += "%s -> %s\n" % (name, res[name])
        return out

    def print_failed(self):
        results = self.get_results()
        for name in self.get_order():
            res = results[name].split()

            if int(res[ResIndexes.failed]) != 0:
                print("Test %s failed %s times."\
                          % (name, res[ResIndexes.failed]))

            if int(res[ResIndexes.count]) == 0:
                print("Test %s hasn't finished after %s seconds (timeout?)."\
                          % (name, res[ResIndexes.time]))

            if int(res[ResIndexes.interr]) != 0:
                print("Test %s had internal error %s times."\
                          % (name, res[ResIndexes.interr]))

            if int(res[ResIndexes.skipped]) != 0:
                print("Test %s was skipped %s times."\
                          % (name, res[ResIndexes.skipped]))


def print_new_missing(result1, result2):
    for name in result1.get_order():
        if not result2.has_test(name):
            print("Test '%s' is not present in the second results." % name)

    for name in result2.get_order():
        if not result1.has_test(name):
            print("New test '%s' is in the second results." % name)

def print_comparison(test_name, res1, res2):
    """Compares testcase results and prints to stdout, ignores runtime."""
    names = ["Failed", "Succeded", "Count", "Time", "Internal Error", "Skipped"]
#    print("Comparing test '%s': %s versus %s" % (test_name, res1, res2))
    res1, res2 = res1.split(), res2.split()
    before, after = [], []

    for i in range(len(res1)):
        if res1[i] != res2[i] and i != ResIndexes.time:
            if res1[i] > res2[i]:
                before.append(names[i])
            else:
                after.append(names[i])

    if before or after:
        print("%s %s -> %s" % (test_name, before, after))

def compare(res_path_1, res_path_2):
    """Compare two result files by a test name."""
    result1, result2 = Result(res_path_1), Result(res_path_2)

    print("Comparing %s and %s" % (res_path_1, res_path_2))
    for name in result1.get_order():
        if result2.has_test(name):
            print_comparison(name,
                             result1.get_result(name),
                             result2.get_result(name))
    print_new_missing(result1, result2)

def print_help():
    print("Finds failures in CTCS2 testrun or compares two CTCS2 testruns.\n")

    print("usage: %s ctcs2_result_dir" % (sys.argv[0]))
    print("usage: %s old_ctcs2_result_dir new_ctcs2_result_dir\n" % (sys.argv[0]))

    print('''When looking for failures all tests with non-zero failure count,
non-zero internal error count, non-zero skipped count or with zero iteration
count (indicates timeout) are printed.\n''')

    print('''When comparing results from two testruns (for the same testsuite!)
all result fields but runtime are compared and differencies printed.
Tests that are listed in the old result directory but not in
the new directory are considered as removed. Tests listed in the
new directory but not in the old directory are considered as added.''')

if __name__ == '__main__':
    if len(sys.argv) == 3:
        compare(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 2:
        if sys.argv[1] == '-h' or sys.argv[1] == '--help':
            print_help()
            sys.exit(0)
        results = Result(sys.argv[1])
        results.print_failed()
    else:
        print_help()
        sys.exit(1)
