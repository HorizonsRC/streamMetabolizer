// b_Kn_pi_eu_plrcko.stan

data {
  // Parameters of priors on metabolism
  real GPP_daily_mu;
  real<lower=0> GPP_daily_sigma;
  real ER_daily_mu;
  real<lower=0> ER_daily_sigma;
  
  // Parameters of hierarchical priors on K600_daily (normal model)
  real K600_daily_meanlog_meanlog;
  real<lower=0> K600_daily_meanlog_sdlog;
  real<lower=0> K600_daily_sdlog;
  
  // Error distributions
  real<lower=0> err_proc_iid_sigma_scale;
  
  // Data dimensions
  int<lower=1> d; # number of dates
  int<lower=1> n; # number of observations per date
  
  // Daily data
  vector[d] DO_obs_1;
  
  // Data
  vector[d] DO_obs[n];
  vector[d] DO_sat[n];
  vector[d] frac_GPP[n];
  vector[d] frac_ER[n];
  vector[d] frac_D[n];
  vector[d] depth[n];
  vector[d] KO2_conv[n];
}

transformed data {
  real<lower=0> timestep; # length of each timestep in days
  timestep = frac_D[1,1];
}

parameters {
  vector[d] GPP_daily;
  vector[d] ER_daily;
  vector<lower=0>[d] K600_daily;
  
  real K600_daily_predlog;
  
  real<lower=0> err_proc_iid_sigma_scaled;
}

transformed parameters {
  vector[d] DO_mod_partial_sigma[n];
  real<lower=0> err_proc_iid_sigma;
  vector[d] GPP_inst[n];
  vector[d] ER_inst[n];
  vector[d] KO2_inst[n];
  vector[d] DO_mod_partial[n];
  
  // Rescale error distribution parameters
  err_proc_iid_sigma = err_proc_iid_sigma_scale * err_proc_iid_sigma_scaled;
  
  // Model DO time series
  // * euler version
  // * no observation error
  // * IID process error
  // * reaeration depends on DO_obs
  
  // Calculate individual process rates
  for(i in 1:n) {
    GPP_inst[i] = GPP_daily .* frac_GPP[i];
    ER_inst[i] = ER_daily .* frac_ER[i];
    KO2_inst[i] = K600_daily .* KO2_conv[i];
  }
  
  // DO model
  for(i in 1:(n-1)) {
    DO_mod_partial[i+1] =
      DO_obs[i] + (
        (GPP_inst[i] + ER_inst[i]) ./ depth[i] +
        KO2_inst[i] .* (DO_sat[i] - DO_obs[i])
      ) * timestep;
    for(j in 1:d) {
      DO_mod_partial_sigma[i+1,j] = err_proc_iid_sigma * 
        timestep ./ depth[i,j];
    }
  }
}

model {
  // Process error
  for(i in 2:n) {
    // Independent, identically distributed process error
    DO_obs[i] ~ normal(DO_mod_partial[i], DO_mod_partial_sigma[i]);
  }
  // SD (sigma) of the IID process errors
  err_proc_iid_sigma_scaled ~ cauchy(0, 1);
  
  // Daily metabolism priors
  GPP_daily ~ normal(GPP_daily_mu, GPP_daily_sigma);
  ER_daily ~ normal(ER_daily_mu, ER_daily_sigma);
  K600_daily ~ lognormal(K600_daily_predlog, K600_daily_sdlog);
  // Hierarchical constraints on K600_daily (normal model)
  K600_daily_predlog ~ normal(K600_daily_meanlog_meanlog, K600_daily_meanlog_sdlog );
  
}
generated quantities {
  vector[d] err_proc_iid[n-1];
  vector[d] GPP;
  vector[d] ER;
  
  for(i in 1:(n-1)) {
    err_proc_iid[i] = (DO_mod_partial[i+1] - DO_obs[i+1]) .* (err_proc_iid_sigma ./ DO_mod_partial_sigma[i+1]);
  }
  for(j in 1:d) {
    GPP[j] = sum(GPP_inst[1:n,j]) / n;
    ER[j] = sum(ER_inst[1:n,j]) / n;
  }
  
}
