function [allAddr,allTs]=loadaerdat(file,maxevents)
%% function [allAddr,allTs]=loadaerdat(file,n);
% loads events from a jEAR .dat/.aedat file.
%
% allAddr are uint32 (or uint16 for legacy recordings) raw addresses.
% allTs are uint32 timestamps (1 us tick).
%
% noarg invocations or invocation with a single decimel integer argument
% open file browser dialog (in the case of no input argument) 
% and directly create vars allAddr, allTs in
% base workspace (in the case of no output argument).
%
% file is the input filename including path.
% maxevents is optional argument to specify maximum number of events
% loaded; maxevents default to 1e6.
%
% Header lines starting with '#' are ignored and printed
%
% It is possible that the header parser can be fooled if the first
% data byte is the comment character '#'; in this case the header must be
% manually removed before parsing. Each header line starts with '#' and
% ends with the hex characters 0x0D 0x0A (CRLF, windows line ending).

defaultmaxevents=5e7;  

if nargin==2,  %nargin表示函数参数输入的数量
       filename=file;    
        path=''; %prettyprints matlab's current search path
end
if nargin==1,
    if ischar(file),%判断file是不是字符数组，如果是返回1，否则返回0
        path='';
        filename=file;
        maxevents=defaultmaxevents;
    else
        maxevents=file
    end
end

if nargin==0,
    maxevents=defaultmaxevents;  %maxevents=5e7
    %displays a dialog box for the user to fill in, and return the
    %filename and path strings and the index of the selected filter.
    [filename,path,filterindex]=uigetfile({'*.*dat','*.aedat, *.dat'},'Select recorded retina data file');
    %如果没有成功，filename为0
    if filename==0, return; end
end

fprintf('Reading at most %d events from file %s\n', maxevents,filename);

f=fopen([path,filename],'r'); %r表示读出
% skip header lines
bof=ftell(f); %获取当前指针的位置
line=native2unicode(fgets(f)); %fgets()从文件中读取一行的内容并且包含换行符；natice2unicode()将数值字节转换为unicode字符表示形式
tok='#!AER-DAT';
version=0;

while line(1)=='#',
    if strncmp(line,tok, length(tok))==1,% 寻找line和tok的前length(tok)个字符是否完全匹配 如果匹配 返回1
        version=sscanf(line(length(tok)+1:end),'%f');%从固定的字符串输入
    end
    fprintf('%s',line); % print line using \n for newline, discarding CRLF written by java under windows %相比于line(1:end-2)这里可以把换行符也打印出来 
    bof=ftell(f); % save end of comment header location
    line=native2unicode(fgets(f)); % gets the line including line ending chars
end

switch version,
    case 0
        fprintf('No #!AER-DAT version header found, assuming 16 bit addresses with version 1 AER-DAT file format\n');
        version=1;
    case 1
        fprintf('Addresses are 16 bit with version 1 AER-DAT file format\n');
    case 2
        fprintf('Addresses are 32 bit with version 2 AER-DAT file format\n');
    otherwise
        fprintf('Unknown AER-DAT file format version %g',version);
end

numBytesPerEvent=6;
switch(version)
    case 1
        numBytesPerEvent=6;
    case 2
        numBytesPerEvent=8;
end
      
fseek(f,0,'eof');  %f现在指向文件的结尾偏移0的位置
numEvents=floor((ftell(f)-bof)/numBytesPerEvent); % 6 or 8 bytes/event %计算事件的数量
if numEvents>maxevents, 
    fprintf('clipping to %d events although there are %d events in file\n',maxevents,numEvents);
    numEvents=maxevents;
end

% read data
%如果是version1那么2个字节的事件被4个字节的时间戳隔开；如果是version2那么4个字节的事件被4个字节的时间戳隔开
fseek(f,bof,'bof'); % start just after header
switch version,
    case 1
        allAddr=uint16(fread(f,numEvents,'uint16',4,'b')); % addr are each 2 bytes (uint16) separated by 4 byte timestamps
        fseek(f,bof+2,'bof'); % timestamps start 2 after bof
        allTs=uint32(fread(f,numEvents,'uint32',2,'b')); % ts are 4 bytes (uint32) skipping 2 bytes after each
    case 2
        allAddr=uint32(fread(f,numEvents,'uint32',4,'b')); % addr are each 4 bytes (uint32) separated by 4 byte timestamps
        fseek(f,bof+4,'bof'); % timestamps start 4 after bof
        allTs=uint32(fread(f,numEvents,'uint32',4,'b')); % ts are 4 bytes (uint32) skipping 4 bytes after each
end

fclose(f);

if nargout==0,  %函数体输出参数的个数
   assignin('base','allAddr',allAddr); %将allAddr的值赋给base空间中的allAddr变量
   assignin('base','allTs',0); %将allTs的值赋给base空间中的allTs变量
   fprintf('%d events assigned in base workspace as allAddr,allTs\n', length(allAddr));
   dt=allTs(end)-allTs(1);
   fprintf('min addr=%d, max addr=%d, Ts0=%d, deltaT=%d=%.2f s assuming 1 us timestamps\n',... 
      min(allAddr), max(allAddr), allTs(1), dt,double(dt)/1e6);  
end

%寻找是否有时间戳不单调的情况 如果存在则进行累加算法使得时间戳递增 
kk=find(allTs(1:end-1)>allTs(2:end)); %返回tpo[]中前一个位置数值比后一个位置数值大的元素位置 kk的长度与tpo无关 有几个满足条件的元素则kk就多长
if ~isempty(kk)  %kk不空
    
    for i=1:length(kk)-1
        allTs(kk(i)+1:kk(i+1))=allTs(kk(i))*ones(size(allTs(kk(i)+1:kk(i+1)))) + allTs(kk(i)+1:kk(i+1));
    end
    allTs(kk(end)+1:end)=allTs(kk(end))*ones(size(allTs(kk(end)+1:end))) + allTs(kk(end)+1:end);
    
end
    
%寻找是否有地址小于零的情况 如果存在则置零
e=find(allAddr<=0);
allAddr(e)=0;

fprintf('Loading events from a jAER .dat/.aedat file finished\n');
end
