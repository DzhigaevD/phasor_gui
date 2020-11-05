% SF core %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function param = SF3D(param,SFtab) 
    uicontrol('Parent',SFtab,'String','Stop SF','Units','normalized',...
        'Position',[0.1 0.18 0.8 0.1],...
        'Callback',@stopReconstruction);

    function stopReconstruction(hObj,callbackdata)            
        param.stopFlag = 1; 
    end

    % Mask for the data threshold
    param.dataMask = param.data>param.dataThreshold;
    
    framesToShow  = 1:param.ShowSteps: param.nSF ;
    framesToShrink = 1:param.SrinkwrapSteps: param.nSF ;
    param.SigmaStart = param.sigma;
    ErrR = zeros(1,param.nSF);

    if param.GPUcheck == 1
        gpuDevice(1);
        param.data = gpuArray(param.data);
        param.O = gpuArray(param.O);
%         param.B = gpuArray(param.B);
        ErrR = gpuArray(ErrR);
    end

    for ii = 1:param.nSF
        if param.stopFlag == 0
            fprintf('SF iteration: %d\n',ii);        
            
            if param.hBackgroundcheck
%                 [Obuffer,param.B] = PM(param.O,param.Bmstop,param.data,param.B); % Modulus projection operator 
            else
                Obuffer = PM(param); % Modulus projection operator
            end
                       
            param.O = 2*PS(Obuffer,param.support)-Obuffer; % Support reflector operator            
            
            if param.hBackgroundcheck  == 1
                param.B = radialAvg3Dset(param,param.nShells);            
            end
            
            if ismember(ii,framesToShrink)        
                [param.support, param.sigma] = shrinkWrap(param,ii,'nSF');
            end

            if ismember(ii,framesToShow)
                ErrR(ii) = calculateMetric(param);
                showProgress(param,fftNc(param.O.*param.support),ErrR);                                              
            end
        elseif param.stopFlag == 1
            break;
        end
        drawnow();
    end  

    % Grab everything from GPU
%     param.B = gather(param.B);
    param.O = gather(param.O);
    param.support = gather(param.support);
    param.data = gather(param.data);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 