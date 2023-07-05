clear;
clc;


% =============================================================
% modify this part only
% =============================================================
% data from OAIZIB
file_pathDICOM_OAIZIBseg = 'path/to/pathDICOM_OAIZIB.xlsx';

% data from OAI
file_MRI00 = 'path/to/mri00.xlsx';
file_KXR_SQ_BU00 = 'path/to/kxr_sq_bu00.xlsx';
file_Gender = 'path/to/enrollees.xlsx';
file_BMI = 'path/to/allclinical00.xlsx';
file_Age = 'path/to/subjectchar00.xlsx';
file_POMA = 'path/to/kmri_poma_tkr_chondrometrics.xlsx';

% output
file_out = 'path/to/Chondrometrics_AllMetrics_AllCases.xlsx';
% =============================================================



% read xlsx (data from OAIZIB)
table_pathDICOM_OAIZIB = readtable(file_pathDICOM_OAIZIBseg, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
varType_pathDICOM_OAIZIB = varfun(@class, table_pathDICOM_OAIZIB, 'OutputFormat', 'cell');
n_sub = size(table_pathDICOM_OAIZIB, 1);

% read xlsx (data from OAI)
table_MRI00 = readtable(file_MRI00, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
var_MRI00 = table_MRI00.Properties.VariableNames;
varType_MRI00 = varfun(@class, table_MRI00, 'OutputFormat', 'cell');

table_KXR_SQ_BU00 = readtable(file_KXR_SQ_BU00, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
var_KXR_SQ_BU00 = table_KXR_SQ_BU00.Properties.VariableNames;
varType_KXR_SQ_BU00 = varfun(@class, table_KXR_SQ_BU00, 'OutputFormat', 'cell');

table_Gender = readtable(file_Gender, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
var_Gender = table_Gender.Properties.VariableNames;
varType_gender = varfun(@class, table_Gender, 'OutputFormat', 'cell');

table_BMI = readtable(file_BMI, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
var_BMI = table_BMI.Properties.VariableNames;
varType_BMI = varfun(@class, table_BMI, 'OutputFormat', 'cell');

table_Age = readtable(file_Age, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
var_Age = table_Age.Properties.VariableNames;
varType_age = varfun(@class, table_Age, 'OutputFormat', 'cell');

table_POMA = readtable(file_POMA, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
var_POMA = table_POMA.Properties.VariableNames;
varType_POMA = varfun(@class, table_POMA, 'OutputFormat', 'cell');


%% Collect data for each subject in the OAI-ZIBseg dataset (#subjects = 507)
% create empty table
idxVar_MRBarCode = find(strcmpi(var_MRI00, {'V00MRBARCD'}));
idxVar_KneeSide = find(strcmpi(var_MRI00, {'V00MRSIDE'}));
idxVar_KLGrade = find(strcmpi(var_KXR_SQ_BU00, {'V00XRKL'}));
idxVar_Gender = find(strcmpi(var_Gender, {'P02SEX'}));
idxVar_Age = find(strcmpi(var_Age, {'V00AGE'}));
idxVar_BMI = find(strcmpi(var_BMI, {'P01BMI'}));
idxVar_POMA = 8:99;

var_out = [{'SubjectID'},{'Path'},{'MRBarCode'},{'KneeSide'},...
    {'KLGrade'},{'Gender'},{'Age'},{'BMI'},...
    var_POMA(idxVar_POMA)];
varType_out = [varType_pathDICOM_OAIZIB,...
    varType_MRI00([idxVar_MRBarCode, idxVar_KneeSide]),...
    varType_KXR_SQ_BU00(idxVar_KLGrade),...
    varType_gender(idxVar_Gender),...
    varType_age(idxVar_Age),...
    varType_BMI(idxVar_BMI),...
    varType_POMA(idxVar_POMA)];
size_table = [n_sub, size(var_out, 2)];
table_out = table('Size', size_table, ...
    'VariableTypes', varType_out, ...
    'VariableNames', var_out);

for i=1:n_sub
    i_subID = num2str(table_pathDICOM_OAIZIB.SubjectID(i));
    i_path = cell2mat(table_pathDICOM_OAIZIB.Path(i));
    i_imgCode = i_path(end-7:end);
    i_barCode_MRI = append('0166', i_imgCode);

    % Get knee side according to subject ID and MRI barcode
    idx_barCode_MRI = ismember(char(table_MRI00.V00MRBARCD), i_barCode_MRI, 'rows');
    idx_subID_MRI = ismember(char(table_MRI00.ID), i_subID, 'rows');
    idx_MRI = idx_barCode_MRI & idx_subID_MRI;
    if sum(idx_MRI)==1
        table_out(i, 1:2) = table_pathDICOM_OAIZIB(i, :);
        table_out(i, 3:4) = table_MRI00(idx_MRI, [5,8]);
        i_kneeSide = table2array(table_MRI00(idx_MRI, 8));
    else
        error('0 or more than 1 matched rows in the source table')
    end

    % Get KL grade according to project number, knee side, and subject ID
    % (get the reading from project 15 first)
    % (get the reading from project 42/37 if the reading from project 15 does not exist)
    idx_kneeSide_XR = ismember(char(table_KXR_SQ_BU00.SIDE), i_kneeSide, 'rows');
    idx_subID_XR = ismember(char(table_KXR_SQ_BU00.ID), i_subID, 'rows');
    idx_project15_XR = ismember(char(table_KXR_SQ_BU00.READPRJ), num2str(15), 'rows');
    idx_XR_p15 = idx_kneeSide_XR & idx_subID_XR & idx_project15_XR;
    if sum(idx_XR_p15)==1
        table_out(i, 5) = table_KXR_SQ_BU00(idx_XR_p15, 15);
    elseif sum(idx_XR_p15)==0
        idx_project37_XR = ismember(char(table_KXR_SQ_BU00.READPRJ), num2str(37), 'rows');
        idx_project42_XR = ismember(char(table_KXR_SQ_BU00.READPRJ), num2str(42), 'rows');
        idx_project37or42_XR = idx_project37_XR | idx_project42_XR;
        idx_XR_p37or42 = idx_kneeSide_XR & idx_subID_XR & idx_project37or42_XR;
        if sum(idx_XR_p37or42)==1
            table_out(i, 5) = table_KXR_SQ_BU00(idx_XR_p37or42, 15);
        elseif size(unique(table_KXR_SQ_BU00(idx_XR_p37or42, 15),'rows'),1)==1
            idx_XR_p37or42 = find(idx_XR_p37or42);
            table_out(i, 5) = table_KXR_SQ_BU00(idx_XR_p37or42(1), 15);
        else
            table_out(i, 5) = {nan};
        end
    else
        fprintf('i = %s \n', num2str(i));
        error('K-L grade: more than 1 matched rows in the source table')
    end

    % Get Gender
    idx_subID_Gender = ismember(char(table_Gender.ID), i_subID, 'rows');
    if sum(idx_subID_Gender)==1
        table_out(i, 6) = table_Gender(idx_subID_Gender, idxVar_Gender);
    elseif sum(idx_subID_Gender)==0
        table_out(i, 6) = {nan};
    else
        error('Gender: more than 1 matched rows in the source table')
    end

    % Get Age
    idx_subID_Age = ismember(char(table_Age.ID), i_subID, 'rows');
    if sum(idx_subID_Age)==1
        table_out(i, 7) = table_Age(idx_subID_Age, idxVar_Age);
    elseif sum(idx_subID_Age)==0
        table_out(i, 7) = {nan};
    else
        error('Age: more than 1 matched rows in the source table')
    end

    % Get BMI
    idx_subID_BMI = ismember(char(table_BMI.ID), i_subID, 'rows');
    if sum(idx_subID_BMI)==1
        table_out(i, 8) = table_BMI(idx_subID_BMI, idxVar_BMI);
    elseif sum(idx_subID_BMI)==0
        table_out(i, 8) = {nan};
    else
        error('BMI: more than 1 matched rows in the source table')
    end

    % Get cartilage quantification metrics from the POMA study (data from OAI)
    % (infomation: 'id', 'side', 'visit')
    if ~exist('i_kneeSide', 'var')
        error('Knee Side: no knee side information for subject s%', i_subID)
    end
    idx_subID_POMA = ismember(char(table_POMA.id), i_subID, 'rows');
    idx_kneeSide_POMA = ismember(table_POMA.side, i_kneeSide);
    idx_visit_POMA = table_POMA.visit == 0;
    idx_POMA = idx_subID_POMA & idx_kneeSide_POMA & idx_visit_POMA;
    if sum(idx_POMA)==1
        table_out(i, 9:100) = table_POMA(idx_POMA, idxVar_POMA);
    elseif sum(idx_POMA)==0
        table_out(i, 9:100) = {nan};
    else
        error('POMA: more than 1 matched rows in the source table')
    end
        
end


%% Save to xlsx file
writetable(table_out, file_out, ...
    "FileType", "spreadsheet", ...
    "WriteVariableNames", true, ...
    "Sheet", "subInfo_OAIZIBseg", ...
    "WriteMode","replacefile");
