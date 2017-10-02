% PROGRAM NAME: ps3huggett
clear, clc

% PARAMETERS
beta = .9932; % discount factor 
sigma = 1.5; % coefficient of risk aversion
b = 0.5; % replacement ratio (unemployment benefits)
y_s = [1, b]; % endowment in employment states
PI = [.97 .03; .5 .5]; % transition matrix
y = y_s(1); % set the initial endowment to 1 (when employed)

% ASSET VECTOR
% Why do we have the lower and upper bounds of asset?
a_lo = -2; % lower bound of grid points
a_hi = 5; % upper bound of grid points
% How to decide the size of asset vector?
num_a = 10;

a = linspace(a_lo, a_hi, num_a); % asset (row) vector

% INITIAL GUESS FOR q
% Why is this the range of q?
q_min = 0.98;
q_max = 1;
q_guess = (q_min + q_max) / 2;

% ITERATE OVER ASSET PRICES
% What is the variable aggsav? Excess demand for asset?
aggsav = 1 ;
while abs(aggsav) >= 0.01 ;
    
    % CURRENT RETURN (UTILITY) FUNCTION
    cons = bsxfun(@minus, a', q_guess * a);
    cons = bsxfun(@plus, cons, permute(y_s, [1 3 2]));
    ret = (cons .^ (1-sigma)) ./ (1 - sigma); % current period utility
    
    % INITIAL VALUE FUNCTION GUESS
    v_guess = zeros(2, num_a);
    
    % VALUE FUNCTION ITERATION
    v_tol = 1;
    while v_tol >.0001;
        % CONSTRUCT RETURN + EXPECTED CONTINUATION VALUE
        % generate a random number as the probability of changing state
        X = rand;
        % compute the utility value for all possible combinations of a and a' with e or u:
        if y == y_s(1)
            value_mat = ret + beta * (PI(1,1) * repmat(1 * permute(v_guess, [3 2 1]), [num_a 1]) + PI(1,2) * repmat(b * permute(v_guess, [3 2 1]), [num_a 1]));
            if X > PI(1, 1)
                y = y_s(2);
            end
        else
            value_mat = ret + beta * (PI(2,1) * repmat(1 * permute(v_guess, [3 2 1]), [num_a 1]) + PI(2,2) * repmat(b * permute(v_guess, [3 2 1]), [num_a 1]));
            if X < PI(2, 1)
                y = y_s(1);
            end
        end
        % CHOOSE HIGHEST VALUE (ASSOCIATED WITH a' CHOICE)
        [vfn, pol_indx] = max(value_mat, [], 2);
        vfn = permute(vfn, [3 1 2]);
        
        % what is the distance between current guess and value function
        v_tol = max(abs(vfn - v_guess));
        
        % if distance is larger than tolerance, update current guess and
        % continue, otherwise exit the loop
        v_guess = vfn;
    end;
    
    % KEEP DECSISION RULE
    pol_fn = a(pol_indx);
    
    % SET UP INITITAL DISTRIBUTION
    % What's the stucture and value of Mu?
    Mu = ones(1, num_a, 2); % by Mingyang
    
    % ITERATE OVER DISTRIBUTIONS
    [emp_ind, a_ind, mass] = find(Mu > 0); % find non-zero indices
    
    MuNew = zeros(size(Mu));
    for ii = 1:length(emp_ind)
        apr_ind = pol_indx(emp_ind(ii), a_ind(ii)); % which a prime does the policy fn prescribe?
        MuNew(:, apr_ind) = MuNew(:, apr_ind) + ... % which mass of households goes to which exogenous state?
            (PI(emp_ind(ii), :) * mass)';
    end
    
    % calculate aggregate asset
    aggsav = sum(a);
        
end