function varargout = mvhfunction(L)
% L: the bandwidth to count up to in the LWindow
% 
% SEE ALSO: SYNTHETICEXPERIMENTS, SYNTHETICCASEA, SLEPT2RESID_FGLS,
%           SDWREGIONS, LOCALIZATION, PLM2XYZ, REGIONS/ICELAND,
%           HARIGIT/HS12TOTALTREND
% 
% Last modified by maxvonhippel-at-email.arizona.edu, 10/16/2017
% The Iceland.mat file is based on a ShapeFile by varriag1-at-asu.edu

% ------------------------ DEFAULT VALUES ------------------------ 

% Maximum bandwidth for LWindow.
defval('L', 60);
% Buffered region for Iceland.
defval('TH', {'iceland' 0.5});
% Number of largest eigenfunctions in which to expand.
defval('J', (L + 1)^2);
% The buffer around the region.
defval('XYbuffer', TH{2});
% The actual domain (ie, iceland itself) in the region.
defval('dom', TH{1});
% Initialize XY to point to the domain, buffered.
eval(sprintf('XY = %s(10, %f);', dom, XYbuffer));

% ------------------------ SLEPIAN FUNCTIONS ------------------------ 

% lmcosiW: Matrix with zeroes where cos/sine coefficients will go.
% ronmW: Running index into lmcosi(3:4) unwrapping the orders.
[~, ~, ~, lmcosiW, ~, ~, ~, ~, ~, ronmW] = addmon(L);
% Get the spherical harmonic matrix for the region.
[G, V, ~, ~, ~, ~, MTAP, ~] = glmalpha(TH, L, [], 0, [], [], J);
% Sort the spherical harmonic matrix by decreasing eigenvalue.
[V, vi] = sort(V, 'descend');
G = G(:, vi); if ~isnan(MTAP); MTAP = MTAP(vi); end
% Collect the eigenvector output into a format that PLM2XYZ interprets.
for j = 1:size(G, 2)
   % Create the blanks.
   cosi = lmcosiW(:, 3:4);
   % Stick in the coefficients of the 1st eigentaper.
   cosi(ronmW) = G(:, j);
   % Construct the full matrix.
   CC{j} = [lmcosiW(:,1:2) cosi]; 
end
% Expand eigenfunctions into space.
for i=1:J; [r{i}, lon, lat] = plm2xyz(CC{i}, 1); end
[~, ~, ~, lmc, mzin] = addmon(L);

% ---------------------- CHART SLEPIAN FUNCTIONS ---------------------- 

figure
% Make 9 subplots which we will populare with bandwidth values along
% our LWindow.
ah1 = krijetem(subnum(3, 3));
fig2print(gcf, 'landscape');
  
% Define axes for the main top text.
axes('position', [0, 0, 1, 1]);
% Write some text: 
htext = text(.5, 0.98, ... 
             ['Functions from PLM2SLEP:  dom = ' ...
              num2str(dom) '+' num2str(XYbuffer) ...
              'buffer, Lwindow = ' num2str(L)], ...
             'FontSize', 14, 'FontName', 'Times New Roman');
% Specify that the coordinates provided above are for the middle
% of the text string: 
set(htext, 'HorizontalAlignment', 'center');
set(gca, 'Visible', 'off');

% Set up the 9 individual plots:
% First, the scales we use for plotting our data in GeoShow.
indeks1 = repmat(lon, length(1:181), 1);
indeks2 = repmat(lat(1:181)', 1, length(lon));
% Next, the borders of Greenland and Iceland, which we shown in our figure.
greenlandBorder = greenland(0,0);
icelandBorder = iceland(0,0);
% Now we iterate over and draw the 9 different figures.
for panel=1:9
%   Select and scale the current axis for this subplot.
    axes(ah1(panel));
    ah1(panel)=axesm('mercator',...
                     'Origin', [70 318 0],...
                     'FLatLimit',[-20 20],...
                     'FLonLimit',[-20 20]);
%   Shape axes
    caxis([-max(abs(reshape(peaks, [], 1)))...
            max(abs(reshape(peaks, [], 1)))]);
    geoshow(indeks2, indeks1, r{panel}(1:181,:),...
            'DisplayType', 'texturemap')
%   Draw Greenland & Iceland borders.
    geoshow(greenlandBorder(:,2), greenlandBorder(:,1), ...
            'DisplayType', 'line')
    geoshow(icelandBorder(:,2), icelandBorder(:,1), ...
            'DisplayType', 'line')
    [~, A ,~, XY] = plm2avg(CC{panel}, XY);
    if XYbuffer ~= 0, linem(XY(:,1) ,XY(:,2), ...
            'color', 'white', 'linestyle', '--'); end
%   Write the title to all the figures.
    t = title(['$a$ = ' num2str(panel) ...
               ', $l_{1}$ = ' num2str(V(panel),3) newline ...
               'Avg = ' num2str(A,3)],...
              'FontName', 'Times New Roman',...
              'FontSize', 10, 'Interpreter', 'LaTeX');
%   Rotate/reshape plot - I think this is to account for projection?
    P = get(t, 'position');
    P(2) = (P(2)*1.05) - 0.02;
    set(t, 'position', P);
    pos = get(gca, 'Position');
    pos(2) = pos(2) - 0.05;
    set(gca, 'Position', pos)
end
% Color code with kelicol and show the subsequent colorbar -
% we use just one color bar for all the plots, as they are all on the
% same scale and color gradient.
kelicol
colorbar('location', 'Manual', 'position', [0.93 0.1 0.02 0.81]);

% ---------------------------- GRACE Data ----------------------------

% Now get the monthly grace data
% [potcoffs,cal_errors,thedates]=grace2plmt('CSR', 'RL05', 'POT', 0);
% Project it into Slepians
[slept,cal_errors,thedates,TH,G,CC,V,N]=grace2slept(...
    'CSRRL05', 'iceland', 1, L, 0, 0, 0, J, 'POT', 1);
[dems,dels,mz,lmcosi,mzi,mzo,bigm,bigl,rinm,ronm,demin] = addmon(L);
defval('nmonths',length(thedates));
% Next run SLEPT2RESID to fit my slepian functions
N=max(round((L+1)^2*spharea(TH)),1);
[ESTsignal,ESTresid,ftests,extravalues,total,alphavarall,totalparams, ...
     totalparamerrors,totalfit,functionintegrals,alphavar,fgls_coeff,...
     fgls_2sigma,fgls_pred,fgls_residvar]...
        =slept2resid_fgls(slept,thedates,[3 365.0 182.5],...
        [],[],CC(1:round(N)),TH);
% Because acceleration is twice the coefficient value
fgls_coeff(2) = fgls_coeff(2)*2;
fgls_2sigma(2) = fgls_2sigma(2)*2;
totalparams(2,:) = totalparams(2,:)*365;
% The acceleration is 2*c2
totalparams(3,:) = 2*totalparams(3,:)*365*365;
totalparamerrors(2,:) = totalparamerrors(2,:)*365;
% Acceleration error is 2*c2error
totalparamerrors(3,:) = 2*totalparamerrors(3,:)*365*365;

figure
errorbar(thedates,total,ones(1,length(thedates))*sqrt(alphavarall)*1.99,'k-')
ylim([-500 500]);
hold on
plot(totalfit(:,1),totalfit(:,3),'b-',totalfit(:,1),totalfit(:,3)+totalfit(:,5),'b--',...
    totalfit(:,1),totalfit(:,3)-totalfit(:,5),'b--');
datetick('x',28);
text(datenum('01-Jan-2003'),-1500,...
    ['Slope = ' num2str(totalparams(2,2)) ' +- ' num2str(totalparamerrors(2,2))...
    ' Gt/yr']);
text(datenum('01-Jan-2003'),-1800,...
    ['Acceleration = ' num2str(totalparams(3,2)) ' +- ' num2str(totalparamerrors(3,2))...
    ' Gt/yr']);
ylabel('Mass (Gt)');
title(['Integrated Mass Change for Greenland, L = ' num2str(L) ...
    ', buffer = ' num2str(XYbuffer) ' deg']);


figure
errorbar(thedates,total,ones(1,length(thedates))*sqrt(fgls_residvar)*1.99,'k-');
ylim([-500 500]);
hold on
plot(totalfit(:,1),fgls_pred,'b-');
datetick('x',28);
text(datenum('01-Jan-2003'),-1500,...
    ['Slope = ' num2str(fgls_coeff(1)) ' +- ' num2str(fgls_2sigma(1))...
    ' Gt/yr']);
text(datenum('01-Jan-2003'),-1800,...
    ['Acceleration = ' num2str(fgls_coeff(2)) ' +- ' num2str(fgls_2sigma(2))...
    ' Gt/yr']);
ylabel('Mass (Gt)');
title(['Integrated Mass Change (FGLS), L = ' num2str(L) ...
    ', buffer = ' num2str(XYbuffer) ' deg']);
% figure
% axesm('mercator','Origin', [70 318 0],'FLatLimit',[-20 20],...
%                  'FLonLimit',[-20 20]);
% geoshow(indeks2, indeks1, ESTsignal,'DisplayType', 'texturemap')              
% Prepare outputs
varns={G,V,lmcosiW,dems,dels,mz,lmc,mzin};
varargout=varns(1:nargout);