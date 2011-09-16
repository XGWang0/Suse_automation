%module libqainternalperl
%{
#include <libqainternal.h>
%}
#define DFLTBUFFERSIZE 65536

/*userhandle_out*/
%typemap(in) char *userhandle_out (char temp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
	$1 = temp;
}
%typemap(argout) char *userhandle_out {
	SV *tempsv;
	tempsv = SvRV($input);
	sv_setpv(tempsv,$1);
}

/*username_out*/
%typemap(in) char *username_out (char temp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *username_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}

/*groupnames_out*/
%typemap(in) char *groupnames_out (char temp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *groupnames_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}





/*filehandle_out*/
%typemap(in) char *filehandle_out (char temp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
	$1 = temp;
}
%typemap(argout) char *filehandle_out {
	SV *tempsv;
	tempsv = SvRV($input);
	sv_setpv(tempsv,$1);
}

/*filename_out*/
%typemap(in) char *filename_out (char temp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *filename_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}

/*data_out*/
%typemap(in) char *data_out (char temp[100*DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *data_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}

/*sizeread_out*/
%typemap(in) unsigned int *sizeread_out (unsigned int mytemp) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = &mytemp;
}
%typemap(argout) unsigned int *sizeread_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setiv(tempsv,(IV) *$1);
}




/*servicehandle_out*/
%typemap(in) char *servicehandle_out (char temp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *servicehandle_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}

/*openportscount_out*/
%typemap(in) int *openportscount_out (int mytemp) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = &mytemp;
}
%typemap(argout) int *openportscount_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setiv(tempsv,(IV) *$1);
}

/*openports_out*/
%typemap(in) unsigned int *openports_out (unsigned int mytemp[DFLTBUFFERSIZE]) {
	if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
	if (SvTYPE(SvRV($input)) != SVt_PVAV)
            croak("Argument $argnum is not an array.");
        $1 = mytemp;
}
%typemap(argout) unsigned int *openports_out {
	AV *tempav;
	SV **svs;
	int i;
	tempav = (AV*) SvRV($input);

	svs = (SV **) malloc(*arg3 * sizeof(SV *));
	for(i=0; i < *arg3;i++) {
		svs[i]=sv_newmortal();
		sv_setiv((SV*) svs[i], (IV) $1[i]);
	}

	tempav = av_make(*arg3,svs);
	free(svs);
}





/*commandhandle_out*/
%typemap(in) char *commandhandle_out (char temp[DFLTBUFFERSIZE]) {
        if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *commandhandle_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}

/*pid_out*/
%typemap(in) unsigned int *pid_out (unsigned int mytemp) {
        if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = &mytemp;
}
%typemap(argout) unsigned int *pid_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setiv(tempsv,(IV) *$1);
}



/*confighandle_out*/
%typemap(in) char *confighandle_out (char temp[DFLTBUFFERSIZE]) {
        if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *confighandle_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}

/*origconffilename_out*/
%typemap(in) char *origconffilename_out (char temp[DFLTBUFFERSIZE]) {
        if (!SvROK($input))
            croak("Argument $argnum is not a reference.");
        $1 = temp;
}
%typemap(argout) char *origconffilename_out {
        SV *tempsv;
        tempsv = SvRV($input);
        sv_setpv(tempsv,$1);
}





bool printInfo(const char * message, ...);
bool printError(const char * message, ...);
bool printWarning(const char * message, ...);
bool printFailed(const char * message, ...);
bool printPassed(const char * message, ...);
bool print(const char * message, ...);
%include <libqainternal.h>
