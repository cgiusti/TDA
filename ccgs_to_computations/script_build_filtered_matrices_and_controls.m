% ----------------------------------------------------------------
% BUILD FILTERED MATRICES AND CONTROLS
%
% Beginning from a CCG matrix, construct a family of graphs
% filtered by Erdos-Renyi p. In addition, construct two 
% collections of filtered families of control graphs: an 
% "Erdos-Renyi" family obtained by shuffling the entries of the
% CCG matrix, and a WME family obtained by sampling from an 
% approximate WME family for the degree seuqence of the CCG graph.
% 
% This script assumes that a maximal CCG matrix and all 
% associated data has been loaded using the script 
% SETUP COMPUTATIONS or an equivalent process.
% ----------------------------------------------------------------

% ----------------------------------------------------------------
% "Pare down" the maximal CCG matrix to produce a graph whose 
% entries are normalized, assymetric cross correlations between
% point processes. Then threshold the weights in the CCG matrix to 
% produce a filtered sequence of graph adjacency matrices whose 
% filtration levels are given by the Erdos-Renyi p of the graph.
% ----------------------------------------------------------------

totalCCG = maximal_ccg_to_total_asymmetric_normalized_ccg(ccgMatrix, ...
    Parameters.CCGWindowWidth, Parameters.effectiveExperimentLength, ...
    firingRates, Parameters.samplingFrequency);

filteredCCGGraphs = weighted_graph_to_p_thresholded_graphs(totalCCG,...
    Parameters.PStep, Parameters.MaxP);

% ----------------------------------------------------------------
% Approximate the WME distribution for the degree sequence of the 
% CCG matrix using the method of gradient descent. 
%
% NOTE: As written, this process may not terminate, but it seems
% to do so in practice. This code is ad hoc and awaits a paper 
% by Chris Hillar which discusses more reasonable approaches to
% computing the distribution parameters.
% ----------------------------------------------------------------

d = sum(totalCCG,2);  % degree sequence
relMin = min(d);

theta_err = abs(length(d) - sum(abs(d))); 
guess = 1;
while (theta_err/min(d) > 0.001)
%	disp(sprintf('Finding thetas, guess size = %g, last error = %g', ...
%        guess, theta_err));
	[theta, theta_err] = fminunc(@(th)wme_parameter_error(th, d), ...
        guess*ones(size(d)));
	guess = guess + randi(100);
end
%disp(sprintf('Final theta error= %g', theta_err));

% ----------------------------------------------------------------
% Build controls by repeatedly shuffling the CCG matrix entries
% and sampling from the WME distribution, then filtering the 
% resulting graphs by ER p.
% ----------------------------------------------------------------

shuffledTotalCCG = cell(Parameters.numControls,1);
filteredShuffledCCGGraphs = cell(Parameters.numControls,1);

WMEGraphs = cell(Parameters.numControls,1);
filteredWMEGraphs = cell(Parameters.numControls,1);

for j=1:Parameters.numControls

    % Shuffle CCG matrix entries and filter -- this is equivalent to
    % shuffling each of the filtered data graphs in a compatible way
    
    shuffledTotalCCG{j} = shuffle_symmetric_matrix_entries(totalCCG);
    filteredShuffledCCGGraphs{j} = ...
        weighted_graph_to_p_thresholded_graphs(shuffledTotalCCG{j}, ...
        Parameters.PStep, Parameters.MaxP);

    % Sample from the WME distribution for the data CCG matrix and 
    % then filter the resulting graph
 
    WMEGraphs{j} = sample_wme_graph(theta);
    filteredWMEGraphs{j} = weighted_graph_to_p_thresholded_graphs(...
        WMEGraphs{j}, Parameters.PStep, Parameters.MaxP);
    
end