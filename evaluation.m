function [E,all_dispatch_times] = evaluation(P, t, time_windows, num_sites, dispatch_times, work_time, time, max_interrupt_time, penalty)
[x1, y1] = size(P);  % 獲取染色體數量和每個染色體的位元數
num_dispatch_order = y1;  % 派遣順序的大小
H = zeros(1, x1);  % 初始化適應度值
all_dispatch_times = zeros(x1, num_sites);

for i = 1:x1  % 遍歷每個染色體

    actual_dispatch_time = zeros(num_sites, num_dispatch_order);
    travel_to_site = zeros(num_sites, num_dispatch_order);%每個到的時間
    travel_back_site = zeros(num_sites, num_dispatch_order);
    arrival_times = zeros(num_sites, num_dispatch_order);
    site_set_start_times = zeros(num_sites, num_dispatch_order);
    work_start_times = zeros(num_sites, num_dispatch_order);%每個開始時間
    finish_time_site = zeros(num_sites, num_dispatch_order);%每個結束時間
    return_times = zeros(num_sites, num_dispatch_order);
    truck_waiting_times = zeros(num_sites, num_dispatch_order);
    site_waiting_times = zeros(num_sites, num_dispatch_order);
    truck_availability = zeros(1, t);  % 追踪每台卡車何時可以再次使用

    penalty_side_time = 0;  % 每個工地的懲罰時間
    penalty_truck_time = 0;  % 卡車等待懲罰時間
    dispatch_times_for_chromosome = dispatch_times(i,:);%每行染色體的派遣時間(t個)
    dispatch_order_for_chromosome = P(i, :);%每個染色體派遣順序



    for k = 1:num_dispatch_order %開始進入每個族群染色體
        dispatch_order_for_chromosome(k) = P(i,k);
        site_id = dispatch_order_for_chromosome(k);

        travel_to_site(k) = time(site_id, 1);  % 到工地的時間
        travel_back_site(k) = time(site_id, 2);  % 到工場的時間
        site_set_start_times(k) = time_windows(site_id,1);

        if site_id < 1 || site_id > num_sites
            error('site_id 超出有效範圍: %d', site_id);
        end

        %設計工地派遣時間 開始被派遣
        if k <= t
            truck_id = k;
            actual_dispatch_time(k) = dispatch_times_for_chromosome(k);
            arrival_times(k) = actual_dispatch_time(k) + travel_to_site(k);  % 到达时间
            work_start_times(k) = max(arrival_times(k), site_set_start_times(k));  % 工作开始时间
        else %派遣t台車後
            % 更新卡車的可用時間
            [next_available_time, truck_id] = min(truck_availability);
            actual_dispatch_time(k) = next_available_time;
            arrival_times(k) = actual_dispatch_time(k) + travel_to_site(k);  % 计算到达时间
        end


        % 检查之前是否有卡车在该工地工作
        previous_work_idx = find(dispatch_order_for_chromosome(i:k-1) == dispatch_order_for_chromosome(k), 1, 'last');  % 查找前一辆卡车的工作记录
        if isempty(previous_work_idx)
            % 如果这是该工地的第一台卡车
            work_start_times(k) = max(arrival_times(k), site_set_start_times(site_id));  % 工作开始时间为到达时间或工地的开始时间
        else
            % 如果已经有卡车到过该工地，设置当前卡车的工作开始时间为前一台卡车的完成时间
            work_start_times(k) = max(arrival_times(k), finish_time_site(previous_work_idx));  % 工作开始时间为到达时间或前一辆卡车的完成时间
        end

        % 提前计算工地完成时间和卡车返回时间
        finish_time_site(k) = work_start_times(k) + work_time(site_id);  % 工地的完成时间
        return_times(k) = finish_time_site(k) + travel_back_site(k);  % 卡车返回时间
        truck_availability(truck_id) = return_times(k);  % 更新卡车的可用时间

        % 计算等待时间
        if ~isempty(previous_work_idx)
            % 如果之前有车已经到过该工地，判断是卡车等待还是工地等待
            if arrival_times(k) < finish_time_site(previous_work_idx)
                truck_waiting_times(k) = finish_time_site(previous_work_idx) - arrival_times(k);
                penalty_truck_time=penalty_truck_time+truck_waiting_times(k);
            elseif arrival_times(k) > finish_time_site(previous_work_idx)
                site_waiting_times(k) = arrival_times(k) - finish_time_site(previous_work_idx);
                if site_waiting_times(k) > max_interrupt_time(site_id)
                    penalty_side_time = penalty_side_time + 1;  % 增加懲罰
                end
            end
        else
            % 第一次到该工地
            if arrival_times(k) < site_set_start_times(k)
                truck_waiting_times(k) = site_set_start_times(k) - arrival_times(k);
                penalty_truck_time=penalty_truck_time+truck_waiting_times(k);
            else
                site_waiting_times(k) = arrival_times(k) - site_set_start_times(k);
                if site_waiting_times(k) > max_interrupt_time(site_id)
                    penalty_side_time = penalty_side_time + 1;  % 增加懲罰
                end
            end
        end

        all_dispatch_times(i, k) = actual_dispatch_time(k);  % 保存派車回到工廠的時間
    end

    total_penalty = penalty_side_time*penalty + penalty_truck_time;  % 總懲罰值
    H(i) = total_penalty;  % 適應度值
end

E = H;  % 返回適應度值
end
