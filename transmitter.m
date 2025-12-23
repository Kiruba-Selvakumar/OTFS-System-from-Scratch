function cp_txsignal_t = tx(rawsymbols, gtx_t, N_cp, delay_max, doppler_max, M, N)

    % I'm assuming rawsymbols is a vector of appropriate size so that it fits into the DD grid with pilot and guard bands

    ddgrid = zeros(M, N); % Initialize Delay Doppler grid
    
    % Introduce pilot at center of the grid
    delaycenter_idx = floor(M/2) + rem(M,2);
    dopplercenter_idx = floor(N/2) + rem(N,2);
    ddgrid(delaycenter_idx, dopplercenter_idx) = 1;


    % Surround pilot symbol with guard band of zeros (they've been set to zero already)

    % Map raw symbols to Delay Doppler grid (excluding pilot and guard band)
    idx = 1;
    for m = 1:M
        for n = 1:N
            % Check if the current position is outside the guard band around the pilot
            if ~((m >= delaycenter_idx-delay_max && m <= delaycenter_idx+delay_max) && (n >= dopplercenter_idx-doppler_max && n <= dopplercenter_idx+doppler_max))
                ddgrid(m,n) = rawsymbols(idx);
                idx = idx + 1;
            end
        end
    end

    % Delay Doppler grid to Delay Time grid (M delays and N Dopplers) 
    dtgrid = ifft(ddgrid,[],2) * sqrt(size(ddgrid,2)); % IFFT along Doppler (along a row) (use the sqrt(N) definition)

    % Pulse shaping in Delay Time domain; multiply each column with gtx_t
    pulseShaped_dtgrid = gtx_t .* dtgrid;

    % Vectorisation of the Pulse shaped Delay Time grid. Columns stacked below each other
    txsignal_t = reshape(pulseShaped_dtgrid, [], 1);

    % Add CP to the transmitted signal
    cp_txsignal_t = [txsignal_t(end-N_cp+1:end); txsignal_t]; % Add CP of length N_cp
end
