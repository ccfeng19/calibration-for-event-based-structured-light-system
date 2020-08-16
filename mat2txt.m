function mat2txt(file_name,matrix)
%% function mat2txt(file_name,matrix)
% ������matrix����������׺���ļ�
%
% ת���� .txt ������mat2txt('filename.txt',data);
% ת���� .corr ������mat2txt('filename.corr',data);

fop=fopen(file_name,'wt');

[M,N]=size(matrix);

for m=1:M
    for n=1:N
        fprintf(fop,'%s %s %s\n',mat2str(m),mat2str(n),mat2str(matrix(m,n)));
    end
    fprintf(fop,'\n');
end
fclose(fop);

end