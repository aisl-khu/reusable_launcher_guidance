function [N,E,D]= Compute_cvx_Euler_Obj_empty(position,velocity,N_step)
    % Compute optimal thrust and Return initial thrust (NED)
    
%.. Global and Persistent Variables 

    global  datThr  datSim    datRlv    datUnit
    global  outDyn  outSim
    
%.. Local Variables

    delt                =   datSim.dt;                                            % dt
    Alpha               =   1/( datThr.Isp * datUnit.AGRAV);                      % Fuel consumption
    g_e                 =   datUnit.AGRAV;                                        % Earth grvity
    r_0                 =   position;                                             % Initial position in L-Coord.
    v_0                 =   velocity;                                             % Initial velocity in L-Coord.
    r_f                 =   datRlv.Rbllf;                                         % Final position in L-Coord.
    v_f                 =   datRlv.Vbllf;                                         % Final velocity in L-Coord.
    Mass                =   outDyn.Mass;
    
    for t = 1:N_step+1
        z_0(t) = log(Mass - Alpha * datThr.ThrustUpper * (t-1) * delt);
        Mu1(t) = datThr.ThrustLower * exp(-z_0(t));
        Mu2(t) = datThr.ThrustUpper * exp(-z_0(t));
    end
    
 %.. compute cvx
 
    cvx_begin
        cvx_precision low
        
        variable u(3,N_step+1)
        variable r(3,N_step+1)
        variable v(3,N_step+1)
        variable Sigma_var(N_step+1)
        variable z(N_step+1)
        
        
        subject to
            r(:,1) == r_0
            v(:,1) == v_0
            r(:,end) == r_f
            v(:,end) == v_f
            
            for t = 1:N_step
                
                r(:,t+1) == r(:,t) + delt * (v(:,t))
                v(:,t+1) == v(:,t) + delt * (u(:,t)+ [0;0;g_e])
                z(t+1) == z(t) - Alpha * delt * (Sigma_var(t))
                norm( u(:,t) ) <= Sigma_var(t)
                Mu1(t) * ( 1 - ( z(t) - z_0(t) )) <= Sigma_var(t)
                Sigma_var(t) <= Mu2(t) * (1 - ( z(t) - z_0(t) ))
                z_0(t) <= z(t)
                z(t) <= log( Mass - Alpha * datThr.ThrustLower * (t-1) * delt)

                
            end

            norm(u(:,end)) <= Sigma_var(end)
            Mu1(end) * ( 1 - (z(end) -z_0(end))) <= Sigma_var(end)
            Sigma_var(:,end) <= Mu2(end) * (1 - (z(end) - z_0(end)))
            z_0(end) <= z(end)
            z(end) <= log(Mass - Alpha * datThr.ThrustLower * N_step * delt)

    cvx_end
    
    
    Check = convertCharsToStrings(cvx_status);
    if Check == "Solved"
        outSim.test_inf = outSim.test_inf + 1;
        N = u(1,1) .* exp(z(1));
        E = u(2,1) .* exp(z(1));
        D = u(3,1) .* exp(z(1));
        
    else
        
        N = 0;
        E = 0;
        D = 0;
    end
    
    
end


