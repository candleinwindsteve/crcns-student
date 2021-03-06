%% This exercise uses fake neurons to test the effectivemess of cross-correlation
% measures for assessing functional connectivity.

%% Generate a stimulus

tlength = 15000;            % The stimulus last 15 seconds at 1kHz sampling rate
stim = randn(1,tlength);    % It is gaussian WN


%% Let's create some fake data for two independent cells that respond to our
% stimulus 

% The first cell has an exponential filter with a 20 ms time constant
th=1:100;
h1 = exp(-th./25);
resp1 = conv(stim,h1,'same');

% The second cell has an exponential filter with a 30 ms time constant
h2 = exp(-th./30);
resp2 = conv(stim, h2, 'same');


% Threshold and set stimulus driven rms to 14 spikes/s and
% background to 1 spike/s
resp1(resp1<0) = 0.0;
resp2(resp2<0) = 0.0;
resp1 = resp1.*((0.014)./std(resp1));
resp2 = resp2.*((0.014)./std(resp2));  
resp1 = resp1 + 0.001;   % Background rate set at 1 spike/s
resp2 = resp2 +0.001;

% Plot the average responses (resp1 and resp2) of the two cells for the first 200 points.
figure(1);
plot(resp1(1:200),'r');
hold on;
plot(resp2(1:200), 'b');
xlabel('Time ms');
ylabel('Firing Rate (spikes/ms)');
hold off;


%% Calculate the granger causality on these mean rates
maxlags = 50;
alpha = 0.01;

% Does resp1 cause resp2 ?
[F,c_v] = granger_cause(resp2,resp1,alpha,maxlags);
fprintf(1,'Testing neuron1 causing neuron2:\n');
if ( F < c_v)
   fprintf(1,'Not significant: F = %.2f < %.2f\n', F, c_v);
else
   fprintf(1,'Yes: F = %.2f > %.2f\n', F, c_v);
end

%% Exercise 1
% Does resp2 cause resp1 ?  Also check the effect of changing alpha.




%% Now we're going to generate poisson spikes from these responses.
% We are first going to generate independent spike trials
meanfr = 15;   % poisson_gen assumes that the resp is a profile and will threhold it and adjust it to meanfr
numTrials = 5;
spiketimes1 = poisson_gen_spikes(resp1, meanfr, numTrials);
spiketimes2 = poisson_gen_spikes(resp2, meanfr, numTrials);

% Generate a psth for these spike arrival times and compare to
% resp1 and resp2.
psth1 = zeros(1, length(resp1));
psth2 = zeros(1, length(resp2));
resp1_trial = [];
resp2_trial = [];

for i=1:numTrials
    trial = zeros(1, length(resp1));
    trial(spiketimes1{i}) = 1;
    psth1 = psth1 + trial;
    resp1_trial = [resp1_trial trial];
    trial = zeros(1, length(resp1));
    trial(spiketimes2{i}) = 1;
    resp2_trial = [resp2_trial trial];
    psth2 = psth2 + trial;
end

psth1 = psth1./numTrials;
psth2 = psth2./numTrials;

% On the same figure 1, we plot the psth obtained from the two
% neurons and compare to theoretical rate.
figure(1);
hold on;
plot(psth1(1:200), 'r--');
plot(psth2(1:200), 'b--');
xlabel('Time (ms)');
ylabel('Spikes/ms');
hold off;

%% Exercise 2 calculate the granger causality on the individual trials.
% Explain your results. How can you fix it?  Perform that fix?



%% We are now going to model two connected neurons
% First we're going to generate poisson spikes from these responses.

meanfr = 15;   % poisson_gen assumes that the resp is a profile and will threhold it and adjust it to meanfr
spiketimes1 = poisson_gen_spikes(resp1, meanfr, numTrials);

% Second Neuron 1 increases the probability of firing in neuron 2.
th=1:25;
hspike = zeros(1,27);
hspike(3:27) = exp(-th./5);   % 2 ms delay and then exponential with 5 ms decay
hspike = hspike./sum(hspike);
w12 = 1;             % Connectivity weight: 1 is a one to one - one spike causes one spike

psth2 = zeros(1, length(resp2));
clear spiketimes2;
resp2_trial = [];

for i=1:numTrials
    trial = zeros(1, length(resp1));
    trial(spiketimes1{i}) = 1;
    resp2_added = w12.*conv(trial,hspike,'full');
    resp2_tot = resp2 + resp2_added(1:length(resp2));
    spiketimes2(i) = poisson_gen_spikes(resp2_tot, meanfr, 1);
    trial = zeros(1, length(resp1));
    trial(spiketimes2{i}) = 1;
    resp2_trial = [resp2_trial trial];
    psth2 = psth2 + trial;
end
psth2 = psth2./numTrials;
resp2_trial = resp2_trial - repmat(resp2, 1, numTrials);

% Let's plot pairs of spike trains in the first 1000 ms.
figure(2);
for i = 1:numTrials
    subplot(numTrials, 1, i);
    hold on;
    nspikes1 = length(spiketimes1{i});
    for is=1:nspikes1
        t1 = spiketimes1{i}(is);
        if t1 > 1000
            break;
        end
        plot([t1 t1], [0 1], 'k');
    end
    nspikes2 = length(spiketimes2{i});
    for is=1:nspikes2
        t2 = spiketimes2{i}(is);
        if t2 > 1000
            break;
        end
        plot([t2 t2], [0 1], 'r');
    end
    axis([0 1000 0 1]);
    axis off;
    hold off;
end

%% Exercise 3.  Calculate the bi-directional granger causality for this connected case
% Does resp1 cause resp2 ? Explain the results.



%% Now we are going to make neuron 2 a burster by simply adding spikes after
% each of the current spikes in a little gaussian pulse.

th=1:25;
hburst = zeros(1,40);
hburst = exp((th-20).^2./10^2);   % A gaussian pulse
hburst = hburst./sum(hburst);
w22 = 1;  % One will double the firing rate
psth2 = zeros(1, length(resp2));
resp2_trial = [];

for i=1:numTrials
    trial = zeros(1, length(resp1));
    trial(spiketimes2{i}) = 1;
    resp2_added = conv(trial,hburst,'full');
    resp2_added = resp2_added(1:length(resp2));
    spiketimes2_added(i) = poisson_gen_spikes(resp2_added, w22*meanfr, 1);
    trial = zeros(1, length(resp1));
    trial(spiketimes2{i}) = 1;
    trial(spiketimes2_added{i}) = 1;
    psth2 = psth2 + trial(1:length(resp2));
    resp2_trial = [resp2_trial trial];
end
psth2 = psth2./numTrials;
resp2_trial = resp2_trial - repmat(resp2, 1, numTrials);

% Let's plot pairs of spike trains in the first 1000 ms.
figure(3);
for i = 1:numTrials
    subplot(numTrials, 1, i);
    
    nspikes1 = length(spiketimes1{i});
    for is=1:nspikes1
        t1 = spiketimes1{i}(is);
        if t1 > 1000
            break;
        end
        plot([t1 t1], [0 1], 'k');
        hold on;
    end
    nspikes2 = length(spiketimes2{i});
    for is=1:nspikes2
        t2 = spiketimes2{i}(is);
        if t2 > 1000
            break;
        end
        plot([t2 t2], [0 1], 'r');
        hold on;
    end
    nspikes2 = length(spiketimes2_added{i});
    for is=1:nspikes2
        t2 = spiketimes2_added{i}(is);
        if t2 > 1000
            break;
        end
        plot([t2 t2], [0 1], 'g');
        hold on;
    end
    axis([0 1000 0 1]);
    axis off;
    hold off;
end

%% Exercise 4.  Repeat the granger calculation for this example
% Does resp1 cause resp2 ? .

