clc;clear;
addpath('./functions')
addpath('./data')
addpath ~/mosek/8/toolbox/r2014a

% read in data & some general setup
file_name = 'electricitydata';
[xtrain, ytrain, xtest, ytest] = load_data(file_name);
nTrain = length(xtrain);
nTest = 20;
varEst = evar(ytrain);


% generate GSM kernels
options_gen = struct('freq_lb', 0, 'freq_ub', 0.5, ...
                 'var_lb', 0, 'var_ub', 16 / (max(xtrain) - min(xtrain)), ...
                 'Q', 200, ...
                 'nFreqCand', 300, 'nVarCand', 1, ...
                 'fix_var', 0.001, 'sampling', 0 );

[freq, var, Q] = generateGSM(options_gen); % the length of freq or var is Q we need
K = kernelComponent(freq, var, xtrain, xtrain);

% Kernel matrix low rank approximation


% Hyperpara Opt

% ADMM ML Opt
% options_ADMM = struct('rho', 2000, 'MAX_iter', 50, 'nv', varEst, ...
%                       'iniAlpha', 200*ones(Q,1));
% 
% alpha = ADMM_ML(ytrain,K,options_ADMM);


% DCP Opt

L = cell(1,Q);
for kk =1:Q
L{kk} = (cholcov(K{kk})).';
end

Phi = eye(nTrain);
iniAlpha = ini_Alpha('fix', 0, Q, ytrain, K);
options_DCP = struct('verbose',1,'ev',false, ...
                 'nv',varEst, ...
                 'dimension_reduction',true, ...
                 'c_nv',0.0, ...
                 'c_alpha', iniAlpha,...
                 'maxiters', 30);
[alpha,nv,info] = mkrm_optimize(ytrain,Phi,L,options_DCP);


% prediction (test phase)
[pMean, pVar] = prediction(xtrain,xtest,ytrain,nTest,alpha,varEst,freq,var,K);
% [pMean, pVar] = prediction(xtest,nTest,xtrain,ytrain,nTrain,K,alpha,Q,nv,freq,var);

% plot phase
figName = ['./fig/Temp',file_name,'Q',int2str(Q)];
plot_save(xtrain,ytrain,xtest,ytest,nTest,pMean,pVar,figName)





