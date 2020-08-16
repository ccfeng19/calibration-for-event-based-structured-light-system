function mat2txt(file_name,matrix)
%% function mat2txt(file_name,matrix)
% 将矩阵matrix保存成任意后缀的文件
%
% 转换成 .txt 举例：mat2txt('filename.txt',data);
% 转换成 .corr 举例：mat2txt('filename.corr',data);

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