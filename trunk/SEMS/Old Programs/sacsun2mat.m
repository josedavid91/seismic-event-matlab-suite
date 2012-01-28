function [SACdata,SeisData,sacfiles]=sacsun2mat(varargin)
% [SACdata,SeisData,filenames] = SACSUNMAT('file1','file2',..., 'filen' )
%
% reads n SAC files file1, file2, filen (SAC files are assumed to have
% SUN byte order) and converts them to matlab
% format. The filenames can contain globbing characters (e.g. * and ?).
% These are expanded and all matching files loaded.
%
% SACSUNMAT( cellarray ) where cellarray={'file1','file2',...,'filen'}
% is equivalent to the standard form.
% 
% SACdata is an n x 1 struct array containing the header variables
%         in the same format as is obtained by using MAT function
%         of SAC2000.
%         SACdata(i).trcLen contains the number of samples.
%
% SeisData is an m x n array (where m=max(npts1, npts2, ...) )
%         containing the actual data.
%
% filenames is a n x 1 string cell array with the filenames actually read.
%
% Note that writing 
%
%  [SACdata,SeisData] = sacsun2mat('file1','file2',..., 'filen' ) 
%
% is equivalent to the following sequence
% 
% sac2000
% READ file1 file2 .. filen
% MAT
%
% (in fact the failure of above sequence to work properly on my
% system motivated this script).
%
%
% SACSUN2MAT was written by F Tilmann (tilmann@esc.cam.ac.uk) 
% based on sac_sun2pc_mat  by C. D. Saragiotis (I copied the 
% routines doing the actual work from this code but
% used a different header structure and made the routine
% flexible). 
% It was tested on MATLAB5 on a PC but
% should work on newer versions, too.
%
% (C) 2004
%

F = 4-1; % float byte-size minus 1;
K = 8-1; % alphanumeric byte-size minus 1
L = 4-1; % long integer byte-size minus 1;

fnames={};
for i=1:nargin
  if ischar(varargin{i})
    fnames=cell([fnames; cellstr(varargin{i})]);
  elseif iscellstr(varargin{i}) & size(varargin{i},1)==1
    fnames=cell([fnames; varargin{i}']);
  elseif iscellstr(varargin{i}) & size(varargin{i},2)==1
    fnames=cell([fnames; varargin{i}]);
  end
end
% expand globs
sacfiles={};k=1;
for i=1:length(fnames)
  dirlist=dir(fnames{i});
  for j=1:length(dirlist)
    if ~dirlist(j).isdir
      sacfiles{k,1}=dirlist(j).name;
      k=k+1;
    end
  end
end

maxnpts=0;
for i=1:length(sacfiles)
  fid=fopen(sacfiles{i},'rb');
  if fid==-1
    error(sprintf('Could not open SAC file %s',fnames{i}))
  end
  SACdata(i,1)=readSacHeader(fid,F,K,L);
  npts=SACdata(i).trcLen;
  if npts>maxnpts
    maxnpts=npts;
  end
  fprintf('Processing file %d: %s\n',i,sacfiles{i});
  SeisData(npts,i)=0;   % Magnify seis matrix if necessary
  SeisData(:,i)=[ readSacData(fid,npts,F+1); zeros(maxnpts-npts,1)];    % Have to pad with zeros if new data have less data points than some previously read file
end

function hdr = readSacHeader(fileId,F,K,L)
% hdr = readSacHeader(FID)
% sacReadAlphaNum reads the SAC-format header fields and returns most of them. 
%    
%    The output variable, 'hdr' is a structure, whose fields are
%    the fields as in the SACdata structure generated by SAC's
%    matlab command MAT
%    
%    Created by C. D. Saragiotis, August 5th, 2003, modified by F Tilmann
headerBytes = 632;
chrctr = fread(fileId,headerBytes,'uchar');
chrctr = chrctr(:)';
% Read floats
hdr.times.delta  = sacReadFloat(chrctr(1:1+F)); % increment between evenly spaced samples
%hdr.DEPMIN = sacReadFloat(chrctr(5:5+F)); % MINimum value of DEPendent variable
%hdr.DEPMAX = sacReadFloat(chrctr(9:9+F)); % MAXimum value of DEPendent variable
% (not currently used) SCALE  = sacReadFloat(chrctr(13:13+F)); % Mult SCALE factor for dependent variable
%hdr.ODELTA = sacReadFloat(chrctr(17:17+F)); % Observd increment if different than DELTA
hdr.times.b      = sacReadFloat(chrctr(21:21+F)); % Begining value of the independent variable
hdr.times.e      = sacReadFloat(chrctr(25:25+F)); % Ending value of the independent variable
hdr.times.o      = sacReadFloat(chrctr(29:29+F)); % event Origin time
hdr.times.a      = sacReadFloat(chrctr(33:33+F)); % first Arrival time
hdr.times.t0 = sacReadFloat(chrctr(41:41+F));
hdr.times.t1 = sacReadFloat(chrctr(45:45+F));
hdr.times.t2 = sacReadFloat(chrctr(49:49+F));
hdr.times.t3 = sacReadFloat(chrctr(53:53+F));
hdr.times.t4 = sacReadFloat(chrctr(57:57+F));
hdr.times.t5 = sacReadFloat(chrctr(61:61+F));
hdr.times.t6 = sacReadFloat(chrctr(65:65+F));
hdr.times.t7 = sacReadFloat(chrctr(69:69+F));
hdr.times.t8 = sacReadFloat(chrctr(73:73+F));
hdr.times.t9 = sacReadFloat(chrctr(77:77+F));
hdr.times.f      = sacReadFloat(chrctr(81:81+F)); % Fini of event time


hdr.response = sacReadFloat(reshape(chrctr(85:85+10*(F+1)-1),F+1,10)');

hdr.station.stla   = sacReadFloat(chrctr(125:125+F)); % STation LAttitude
hdr.station.stlo   = sacReadFloat(chrctr(129:129+F)); % STation LOngtitude
hdr.station.stel   = sacReadFloat(chrctr(133:133+F)); % STation ELevation
hdr.station.stdp   = sacReadFloat(chrctr(137:137+F)); % STation DePth below surface 

hdr.event.ecla   = sacReadFloat(chrctr(141:141+F)); % EVent LAttitude
hdr.event.evlo   = sacReadFloat(chrctr(145:145+F)); % EVent LOngtitude
hdr.event.evel   = sacReadFloat(chrctr(149:149+F)); % EVent ELevation
hdr.event.evdp   = sacReadFloat(chrctr(153:153+F)); % EVent DePth below surface
hdr.event.mag   = sacReadFloat(chrctr(157:157+F)); % EVent DePth below surface

userdata=sacReadFloat(reshape(chrctr(161:161+10*(F+1)-1),F+1,10)');

hdr.evsta.dist   = sacReadFloat(chrctr(201:201+F)); % station to event DISTance (km)
hdr.evsta.az     = sacReadFloat(chrctr(205:205+F)); % event to station AZimuth (degrees)
hdr.evsta.baz    = sacReadFloat(chrctr(209:209+F)); % station to event AZimuth (degrees)
hdr.evsta.gcarc  = sacReadFloat(chrctr(213:213+F)); % station to event Great Circle ARC length (degrees)

%hdr.DEPMEN = sacReadFloat(chrctr(225:225+F)); % MEaN value of DEPendent variable

hdr.station.cmpaz  = sacReadFloat(chrctr(229:229+F)); % CoMPonent AZimuth (degrees clockwise from north)
hdr.station.cmpinc = sacReadFloat(chrctr(233:233+F)); % CoMPonent INCident angle (degrees from vertical)

hdr.llnl.xminimum = sacReadFloat(chrctr(237:237+L));
hdr.llnl.xmaximum = sacReadFloat(chrctr(241:241+L));
hdr.llnl.yminimum = sacReadFloat(chrctr(245:245+L));
hdr.llnl.ymaximum = sacReadFloat(chrctr(249:249+L));

% Read long integers
hdr.event.nzyear = sacReadLong(chrctr(281:281+L)); % GMT YEAR
hdr.event.nzjday = sacReadLong(chrctr(285:285+L)); % GMT julian DAY
hdr.event.nzhour = sacReadLong(chrctr(289:289+L)); % GMT HOUR
hdr.event.nzmin  = sacReadLong(chrctr(293:293+L)); % GMT MINute
hdr.event.nzsec  = sacReadLong(chrctr(297:297+L)); % GMT SECond
hdr.event.nzmsec = sacReadLong(chrctr(301:301+L)); % GMT MilliSECond

hdr.llnl.norid = sacReadLong(chrctr(309:309+L));
hdr.llnl.nevid = sacReadLong(chrctr(313:313+L));

hdr.trcLen   = sacReadLong(chrctr(317:317+L)); % Number of PoinTS per data component

hdr.llnl.nwfid = sacReadLong(chrctr(325:325+L));
hdr.llnl.nxsize = sacReadLong(chrctr(329:329+L));
hdr.llnl.nysize = sacReadLong(chrctr(333:333+L));

hdr.descrip.iftype = sacReadLong(chrctr(341:341+L)); % File TYPE
hdr.descrip.idep   = sacReadLong(chrctr(345:345+L)); % type of DEPendent variable
hdr.descrip.iztype  = sacReadLong(chrctr(349:349+L)); % reference time equivalence

hdr.descrip.iinst  = sacReadLong(chrctr(357:357+L)); % type of recording INSTrument

% Before there were floats read here?
hdr.descrip.istreg = sacReadLong(chrctr(361:361+F)); % STation geographic REGion
hdr.descrip.ievreg = sacReadLong(chrctr(365:365+F)); % EVent geographic REGion
hdr.descrip.ievtyp = sacReadLong(chrctr(369:369+F)); % EVent geographic REGion
hdr.descrip.iqual  = sacReadLong(chrctr(373:373+F)); % QUALity of data
hdr.descrip.isynth = sacReadLong(chrctr(377:377+F)); % SYNTHetic data flag

hdr.event.imagtyp  = sacReadLong(chrctr(381:381+F));
hdr.event.imagsrc  = sacReadLong(chrctr(385:385+F));

% no logical SAC header variables in matlab SACdata structure!
% previous version set these defaults
% $$$ % SAC defaults
% $$$ hdr.IEVTYPE = 'IUNKN';
% $$$ %IEVTYPE= sacReadFloat(chrctr(369:369+F)); % EVent TYPE
% $$$ hdr.LEVEN = 'TRUE';  % true, if data are EVENly spaced (required)
% $$$ %LEVEN= sacReadFloat(chrctr(421:521+F)); % true, if data are EVENly spaced (required)
% $$$ hdr.LPSPOL = 'FALSE'; % true, if station components have a PoSitive POLarity
% $$$ %LPSPOL= sacReadFloat(chrctr(425:425+F)); % true, if station components have a PoSitive POLarity
% $$$ hdr.LOVROK = 'FALSE'; % true, if it is OK to OVeRwrite this file in disk
% $$$ %LOVROK= sacReadFloat(chrctr(429:429+F)); % true, if it is OK to OVeRwrite this file in disk
% $$$ hdr.LCALDA = 'TRUE'; % true, if DIST, AZ, BAZ and GCARC are to be calculated from station and event coordinates
% $$$ %LCALDA= sacReadFloat(chrctr(433:433+F)); % true, if DIST, AZ, BAZ and GCARC are to be calculated from station and event coordinates

% Read alphanumeric data
hdr.station.kstnm  = sacReadAlphaNum(chrctr(441:441+K)); % STation NaMe
hdr.event.kevnm  = sacReadAlphaNum(chrctr(449:449+2*(K+1)-1)); % EVent NaMe
%hdr.KHOLE  = sacReadAlphaNum(chrctr(465:465+K)); % HOLE identification, if nuclear event
hdr.times.ko     = sacReadAlphaNum(chrctr(473:473+K)); % event Origin time identification
hdr.times.ka     = sacReadAlphaNum(chrctr(481:481+K)); % first Arrival time identification

hdr.times.kt0 = sacReadAlphaNum(chrctr(489:489+K));
hdr.times.kt1 = sacReadAlphaNum(chrctr(497:497+K));
hdr.times.kt2 = sacReadAlphaNum(chrctr(505:505+K));
hdr.times.kt3 = sacReadAlphaNum(chrctr(513:513+K));
hdr.times.kt4 = sacReadAlphaNum(chrctr(521:521+K));
hdr.times.kt5 = sacReadAlphaNum(chrctr(529:529+K));
hdr.times.kt6 = sacReadAlphaNum(chrctr(537:537+K));
hdr.times.kt7 = sacReadAlphaNum(chrctr(545:545+K));
hdr.times.kt8 = sacReadAlphaNum(chrctr(553:553+K));
hdr.times.kt9 = sacReadAlphaNum(chrctr(561:561+K));


hdr.times.kf     = sacReadAlphaNum(chrctr(569:569+K)); % Fini identification
kuser0 = sacReadAlphaNum(chrctr(577:577+K)); % USER-defined variable storage area
kuser1 = sacReadAlphaNum(chrctr(585:585+K)); % USER-defined variable storage area
kuser2 = sacReadAlphaNum(chrctr(593:593+K)); % USER-defined variable storage area
hdr.station.kcmpnm = sacReadAlphaNum(chrctr(601:601+K)); % CoMPonent NaMe
hdr.station.knetwk = sacReadAlphaNum(chrctr(609:609+K)); % name of seismic NETWorK
%hdr.KDATRD = sacReadAlphaNum(chrctr(617:617+K)); % DATa Recording Date onto the computer
%hdr.KINST  = sacReadAlphaNum(chrctr(625:625+K)); % generic name of recording INSTrument

usercell=num2cell(userdata);
[usercell{find(userdata==-12345)}]=deal([]);
[hdr.user(1:10).data]=deal(usercell{:});
[hdr.user(1:10).label]=deal(kuser0, kuser1,kuser2,[], [], [], [], [], [], []);


function X = readSacData(fid,N,F)
% function data = readSacData('filename',NPTS,floatByteSize)
chrctr = fread(fid,N*F,'uchar');
x=reshape(chrctr,F,N)';
%x
X = sacReadFloat(x); 


function lNumber = sacReadLong(cb)
% reads long integers (4 bytes long)
% cb is the character buffer
cb = cb(:);
lNumber = (256.^(3:-1:0))*cb;
if lNumber == -12345, lNumber = []; end

function fNumber = sacReadFloat(cb)
% reads floats (4 bytes long)
% cb is the character buffer
C = size(cb,1);
stringOfBitSequence = [dec2bin(cb(:,1),8) dec2bin(cb(:,2),8) dec2bin(cb(:,3),8) dec2bin(cb(:,4),8)];
bitSequence = stringOfBitSequence=='1';
fSign = -2*bitSequence(:,1)+1;
fExp = bitSequence(:,2:9)*(2.^(7:-1:0)') - 127;
fMantissa = [ones(C,1) bitSequence(:,10:32)]*(2.^(0:-1:-23)');
fNumber = fSign.*fMantissa.*(2.^fExp);
isZeroCheck = sum(bitSequence')'==0;
fNumber = fNumber.*(~isZeroCheck);
if C==1 & fNumber == -12345, fNumber = []; end


function alphaNum = sacReadAlphaNum(cb)
% reads alphanumeric data (8 or 16 bytes long). If it cb is empty, it returns a ' ' 
% cb is the character buffer
K = max(size(cb));
alphaNumTemp = char(cb);
if K == 8
    if alphaNumTemp == '-12345  ' 
        alphaNum = [];
    else
        alphaNum = alphaNumTemp;
    end
else
    if K == 16
        if alphaNumTemp == '-12345   -12345 ' | alphaNumTemp == '-12345          ' 
            alphaNum = [];
        else
            alphaNum = alphaNumTemp;
        end
    end
end
