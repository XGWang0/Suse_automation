/* trivial demo use of libqainternal... */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

#include "libqainternal.h"

int main(int argc,char *argv[])
{
	/* --- data deklarations and definitions --- */

	char buffer[65536];
	char buf2[65536];
	char buf3[65536];
	char userhandle[65536];
	int tmp_int,counter;
	unsigned int tmp_uint;
	char teststring[]="1234567890123456789_RD-QA-Testscript-API_QWERTZ";
	char teststrmd5[]="7308d1006fcbffdbb726a08a94cb901E";
	char wrongmd5[] = "7308d1006fcbffdbb726a08b94cb901f";
	bool  tmp_bool;
	unsigned int uintarray[65536];
    int failed = 0;

	/* --- print introduction --- */
	print(" **** LIBQAINTERNAL-DEMO ****");


	/* --- testing user functions --- */
	printInfo("Testing addUser: for new user foobar");
	if (addUser(userhandle,"foobar","audio")) {
		printPassed("the addUser returned true");

		printInfo("Testing addToGroup: for new user foobar and group modem");
		if (addToGroup(userhandle,"modem")) {
			printPassed("the addToGroup returned true");
		} else {
			printFailed("the addToGroup returned false");
            failed++;
		}
	
		printInfo("Testing getUser: for new user foobar");
		if (getUser(userhandle,buffer)) {
			printPassed("the getUser returned true and username %s",buffer);
		} else {
			printFailed("the getUser returned false");
            failed++;
		}
	
		printInfo("Testing getGroups: for new user foobar");
		if (getGroups(userhandle,buffer)) {
			printPassed("the getGroups returned true and the groupnames %s",buffer);
		} else {
			printFailed("the getGroups returned false");
            failed++;
		}

		printInfo("Testing removeFromGroup: for new user foobar and group modem");
		if (removeFromGroup(userhandle,"modem")) {
			printPassed("the removeFromGroup returned true");
		} else {
			printFailed("the removeFromGroup returned false");
            failed++;
		}
	
	    printInfo("Testing getGroups: for new user foobar");
		if (getGroups(userhandle,buffer)) {
			printPassed("the getGroups returned true and the groupnames %s",buffer);
		} else {
			printFailed("the getGroups returned false");
            failed++;
		}
    
        printInfo("Testing changePassword: for user foobar");
		if (changePassword(userhandle,"yaddayadda")) {
			printPassed("changePassword returned true");
		} else {
			printFailed("changePassword returned false");
            failed++;
		}


		printInfo("Testing delUser: for new user foobar");
		if (delUser(userhandle)) {
			printPassed("the delUser returned true");
		} else {
			printFailed("the delUser returned false");
            failed++;
		}

	} else {
		printFailed("the addUser returned false");
        failed++;
	}


	/* --- testing file functions --- */

	printInfo("Testing createFile: creating file /tmp/foobar");
	if (createFile(buffer,"/tmp/foobar")) {
		printPassed("the createFile returned true and handle %s\n",buffer);
		system("ls -l /tmp/foobar");
	} else {
		printFailed("the createFile returned false");
        failed++;
	}

	printInfo("Testing createFileMinsize: creating a file (/tmp/foobar2) if at least 5GB is free");
	if (createFileMinsize(buf2,"/tmp/foobar2",5ul*1024ul*1024ul*1024ul)) {
		printPassed("the createFileMinsize returned true");
	} else {
		printFailed("the createFileMinsize returned false");
        failed++;
	}

	printInfo("Testing createTempFile:");
	if (createTempFile(buf2)) {
		printPassed("the createTempFile returned true");
		lookupFile(buf2,buf3);
		printf("..found it to be a file named %s (via lookupFile)\n",buf3);
	} else {
		printFailed("the createTempFile returned false");
        failed++;
	}

	printInfo("Testing writeTextFile: writing to just created tempfile");
	if (writeTextFile(buf2,teststrmd5)) {
		printPassed("the writeTextFile returned true");
	} else {
		printFailed("the writeTextFile returned false");
        failed++;
	}

	printInfo("Testing writeBinaryFile: writing to just created tempfile");
	if (writeBinaryFile(buf2,teststrmd5,33)) {
		printPassed("the writeBinaryFile returned true");
	} else {
		printFailed("the writeBinaryFile returned false");
        failed++;
	}

	printInfo("Testing readTextFile: reading the tempfile");
	if (readTextFile(buf2,buf3,&tmp_uint)) {
		printPassed("the readTextFile returned true and string >%s< and %d read bytes\n",buf3,tmp_uint);
	} else {
		printFailed("the readTextFile returned false");
        failed++;
	}

	printInfo("Testing readTextlineFile: reading the tempfile");
	if (readTextlineFile(buf2,buf3,&tmp_uint)) {
		printPassed("the readTextlineFile returned true and string >%s< and %d read bytes\n",buf3,tmp_uint);
	} else {
		printFailed("the readTextlineFile returned false");
        failed++;
	}

	printInfo("Testing readBinaryFile: reading 4 bytes of the tempfile");
	if (readBinaryFile(buf2,buf3,4,&tmp_uint)) {
		buf3[tmp_uint]='\0'; /*adding trailing \0 to not confuse printf*/
		printPassed("the readBinaryFile really read %d bytes that were >%s<\n",tmp_uint,buf3);
	} else {
		printFailed("the readBinaryFile returned false");
	}

	printInfo("Testing lookupFile:");
	if (lookupFile(buffer,buf2)) {
		printPassed("the lookupFile returned true and provided %s as filename\n",buf2);
	} else {
	    printFailed("the lookupFile returned false");
	    failed++;
	}

	printInfo("Testing removeFile: deleting file /tmp/foobar");
	if (removeFile(buffer)) {
		printPassed("the removeFile returned true (ls ..)");
		system("ls -l /tmp/foobar");
	} else {
		printFailed("the removeFile returned false");
        failed++;
	}

	/* --- testing compare functions --- */
    printf("\n\n");
	printInfo("Testing strCompare:");	
	strcpy(buffer,teststring);
	if (strCompare(buffer,teststring)) {
		printPassed("the strCompare of two identical strings returned true");
	} else {
		printFailed("the strCompare of two identical strings returned false");
        failed++;
	}
	if (strCompare(teststrmd5,teststring)) {
        printFailed("the strCompare of two different strings returned true");
        failed++;
    } else {
        printPassed("the strCompare of two different strings returned false");
    }


	printInfo("Testing strnCompare:");	
	if (strnCompare(teststrmd5,wrongmd5,22)) {
		printPassed("the strnCompare of identical stringparts returned true");
	} else {
		printFailed("the strnCompare of identical stringparts returned false");
        failed++;
	}
	/*we use same strings here, but now on a length where they will differ*/
	if (strnCompare(teststrmd5,wrongmd5,32)) {
        printFailed("the strnCompare of differing stringparts returned true");
        failed++;
    } else {
        printPassed("the strnCompare of differing stringparts returned false");
    }


	printInfo("Testing md5Compare:");
	printInfo("comparing teststring and corresponding md5sum:");
	tmp_bool = md5Compare(teststring, sizeof(teststring), teststrmd5);
	if (tmp_bool) {
		printPassed("the md5Compare returned true");
	} else {
		printFailed("the md5Compare returned false");
        failed++;
	}
	printInfo("comparing teststring with wrong md5sum:");
    tmp_bool = md5Compare(teststring, sizeof(teststring), wrongmd5);
    if (tmp_bool) {
            printFailed("the md5Compare returned true");
            failed++;
    } else {
            printPassed("the md5Compare returned false");
    }


	/* --- service functions --- */
	printInfo("Testing associateService: for sshd");
	if (associateService(buf2,"sshd")) {
		printPassed("the associateService returned true (handle:%s)\n",buf2);
	} else {
		printFailed("the associateService returned false");
        failed++;
	}

	printInfo("Testing checkService: for sshd");
	if (checkService(buf2)) {
		printPassed("the checkService (for sshd) returned true");
	} else {
		printFailed("the checkService (for sshd) returned false");
        failed++;
	}

	printInfo("Testing startService: for atd");
	if (associateService(buf3,"atd") && startService(buf3)) {
		printPassed("the startService (for atd) returned true");
	} else {
		printFailed("the startService (for atd) returned false");
        failed++;
	}

	printInfo("Testing checkService: for atd");
	if (checkService(buf3)) {
		printPassed("the checkService (for atd) returned true");
	} else {
		printFailed("the checkService (for atd) returned false");
        failed++;
	}

	printInfo("Testing restartService: for atd");
	if (restartService(buf3)) {
		printPassed("the restartService (for atd) returned true");
	} else {
		printFailed("the restartService (for atd) returned false");
        failed++;
	}

	printInfo("Testing of checkService: for atd");
	if (checkService(buf3)) {
		printPassed("the checkService (for atd) returned true");
	} else {
		printFailed("the checkService (for atd) returned false");
        failed++;
	}

	printInfo("Testing of openportsOfService: for sshd");
	if (openportsOfService(buf2,uintarray,&tmp_int)) {
		printPassed("the openportsOfService (for sshd) returned true");
		printf("openportsOfService reported %d open ports\n",tmp_int);
		for (counter=0; counter < tmp_int; counter++) {
			printf("openport nr.%d is %d\n",counter+1,uintarray[counter]);
		}
	} else {
		printFailed("the openportsOfService (for sshd) returned false");
        failed++;
	}

	printInfo("Testing stopService: for atd");
	if (stopService(buf3)) {
		printPassed("the stopService (for atd) returned true");
	} else {
		printFailed("the stopService (for atd) returned false");
        failed++;
	}

	printInfo("Testing (again) checkService: for atd");
	if (checkService(buf3)) {
		printFailed("the checkService (for atd) returned true");
        failed++;
	} else {
		printPassed("the checkService (for atd) returned false");
	}


	/* --- execute functions --- */
	printInfo("Testing of associateCmd: for ls -l /tmp/qainternal");
	if (associateCmd(buf2,"/bin/ls","-l /tmp/qainternal*")) {
		printPassed("the associateCmd returned true");
	} else {
		printFailed("the associateCmd returned false");
        failed++;
	}

	printInfo("Testing of runCmd: for ls -l /tmp/qainternal");
	if (runCmd(buf2)) {
		printPassed("the runCmd returned true");
	} else {
		printFailed("the runCmd returned false");
        failed++;
	}
	
	printInfo("Testing of runCmdAs: for id");
	associateCmd(buf2,"id","");
	if (! addUser(userhandle,"foobar2",NULL)) {
		fprintf(stderr,"you need to be root!! aborting \n");
		exit(1);
	}
	if (runCmdAs(buf2,userhandle)) {
		printPassed("the runCmdAs returned true");
	} else {
		printFailed("the runCmdAs returned false");
        failed++;
	}
	delUser(userhandle);
	printInfo("Testing runCmd: again for id");
	if (runCmd(buf2)) {
		printPassed("the runCmd returned true");
	} else {
		printFailed("the runCmd returned false");
        failed++;
	}

	printInfo("Testing runCmdAsync: for id");
	if (runCmdAsync(buf2)) {
		printPassed("the runCmdAsync returned true");
	} else {
		printFailed("the runCmdAsync returned false");
        failed++;
	}

	printInfo("Testing pidOfCmd: for id");
	if (pidOfCmd(buf2,&tmp_uint)) {
		printPassed("the pidOfCmd returned true and pid %u\n",tmp_uint);
	} else {
		printFailed("the pidOfCmd returned false");
        failed++;
	}

	printInfo("Testing killPid: for setup sleep 60 cmd");
	associateCmd(buf2,"sleep","60");
	pidOfCmd(buf2,&tmp_uint);
	printf("sleep-cmd has pid %u\n",tmp_uint);
	if (killPid(tmp_uint)) {
		printPassed("the killPid returned true");
	} else {
		printFailed("the killPid returned false");
        failed++;
	}


	/* --- config functions --- */
    printf("\n\n");
	printInfo("Testing copyConfig: for /etc/exports");
	if (copyConfig(buf2,"/etc/fstab","/etc/exports")) {
		printPassed("the copyConfig returned true");
	} else {
		printFailed("the copyConfig returned false");
        failed++;
	}

	printInfo("Testing checkConfig: for /etc/exports");
	if (checkConfig(buf2,buf3)) {
		printPassed("the checkConfig returned true and orig-conffile %s\n",buf3);
	} else {
		printFailed("the checkConfig returned false");
        failed++;
	}

	printInfo("Testing removeConfig: for /etc/exports");
	if (removeConfig(buf2)) {
		printPassed("the removeConfig returned true");
	} else {
	    printFailed("the removeConfig returned false");
	    failed++;
	}

    printInfo("Testing copyConfig: for /etc/sysconfig/");
	if (copyConfig(buf2,"/etc/init.d","/etc/sysconfig")) {
		printPassed("the copyConfig returned true");
        system("ls /etc/sysconfig");
	} else {
		printFailed("the copyConfig returned false");
        failed++;
	}

	printInfo("Testing removeConfig: for /etc/sysconfig/");
	if (removeConfig(buf2)) {
		printPassed("the removeConfig returned true");
        system("ls /etc/sysconfig");
	} else {
	    printFailed("the removeConfig returned false");
	    failed++;
	}



	/* --- cleanup function --- */
    printf("\n\n");
	printInfo("Testing cleanup: filehandles");
	if (cleanup("files")) {
		printPassed("the cleanup (of files) returned true");
	} else {
		printFailed("the cleanup (of files) returned false");
        failed++;
	}

	printInfo("Testing cleanup: all handles");
	if(createTempFile(buf2) && cleanup("all")) {
		printPassed("then cleanup (of all) returned true");
	} else {
		printFailed("then cleanup (of all) returned false");
        failed++;
	}

	
	/* --- testfunctions --- */

	printInfo("Testing qa_hello:");
	qa_hello();

    printf("---------------\n");
    printf("Failed tests: %d\n",failed);

	return((failed) ? FAILED : PASSED);
}
