% non(separable) Dataset

M = 10; % mod
R = 4;
maxIte = 10;
NTrials = 10;
trainErrorCP = zeros(NTrials, 1);
testErrorCP = zeros(NTrials, 1);
trainErrorGP = zeros(NTrials, 1);
testErrorGP = zeros(NTrials, 1);
trainErrorRFF = zeros(NTrials, 1);
testErrorRFF = zeros(NTrials, 1);
timeWallGP = zeros(NTrials, 1);
timeWallCP = zeros(NTrials, 1);
% timeWallRFF = zeros(NTrials, 1);

data_str = 'sep2_data.dat';
increase_runtime = true;
D = 4;

warning('off', 'all');
for ite = 1:NTrials
    rng(ite);
    X = load(data_str);
    perm = randperm(size(X, 1));
    X = X(perm,:);
    X = X(1:floor(0.90 * size(X, 1)), :);
    Y = X(:, end);
    X = X(:,1:end - 1);

    YMean = mean(Y);    YStd = std(Y);
    XMin = min(X);  XMax = max(X);
    Y = (Y - YMean)./YStd;
    X = (X - XMin)./(XMax - XMin);
    meanfunc = [];                    
    covfunc = @covSEiso; 
    likfunc = @likGauss; 
 
    hyp = struct('mean', [], 'cov', [0 0], 'lik', -1);
    hyp2 = minimize(hyp, @gp, -200, @infGaussLik, meanfunc, covfunc, likfunc, X, Y); 
    
    trainErrorGP(ite) = mean((gp(hyp2, @infGaussLik, meanfunc, covfunc, likfunc, X, Y, X)-Y).^2); 
    
    lengthscale = exp(hyp2.cov(1));
    lambda = exp(hyp2.lik-hyp2.cov(2))^2;
    tic;
    WCP = CPLS(X, Y, M, R, lambda, lengthscale, maxIte);
    timeWallCP(ite) = toc;
    trainErrorCP(ite) = mean((Y - CPPredict(X, WCP, lengthscale)).^2);
    
    % RFF
    tic;
    if increase_runtime
        [ZZ, ZY, W, B] = RFF(X, Y, M ^ D, lengthscale);
        wRFF = (ZZ + lambda*eye(M ^ D))\(ZY);
    else
        [ZZ, ZY, W, B] = RFF(X, Y, R * M, lengthscale);
        wRFF = (ZZ + lambda*eye(R * M))\(ZY);
    end
    timeWallRFF(ite) = toc;
    trainErrorRFF(ite) = mean((Y-RFFPredict(X,W,B)*wRFF).^2);

    % Test
    XTest = load(data_str);
    XTest = XTest(perm, :);
    XTest = XTest(floor(0.90 * size(XTest, 1)) + 1:end, :);
    YTest = XTest(:, end);
    XTest = XTest(:, 1:end - 1);
    XTest = (XTest - XMin)./(XMax - XMin);
    YTest = (YTest - YMean)./YStd;
    testErrorCP(ite) = mean((YTest - CPPredict(XTest, WCP, lengthscale)).^2);
    testErrorGP(ite) = mean((YTest - gp(hyp2, @infGaussLik, meanfunc, covfunc, likfunc, X, Y, XTest)).^2); 
    testErrorRFF(ite) = mean((YTest - RFFPredict(XTest, W, B) * wRFF).^2);
end