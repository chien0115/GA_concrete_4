function [Y, dispatch_times_new2] = mutation(P, t, dispatch_times)
    % P = Population
    % dispatch_times = Matrix of dispatch times corresponding to the chromosomes

    [x1, y1] = size(P); % Population size (x1) and chromosome length (y1)
    
    % 隨機選擇一個染色體
    r1 = randi(x1); % 隨機選擇族群內的索引
    A1 = P(r1, 1:y1); % 取出選中的染色體 (派遣順序)
    dispatch_times1 = dispatch_times(r1, :); % 取出對應的派遣時間

    % 定義派遣順序的三個突變位置
    pos = randperm(y1, 3); % 隨機選擇三個不同的位置

    % 交換所選三個位置的值，這裡可以做三點交換
    % 比如：將pos1的值給pos2，pos2的值給pos3，pos3的值給pos1
    temp = A1(pos(1));
    A1(pos(1)) = A1(pos(2));
    A1(pos(2)) = A1(pos(3));
    A1(pos(3)) = temp;

    % 同樣對派遣時間進行三點變異
    if t >= 3
        pos_dispatch = randperm(t, 3); % 隨機選擇三個不同的位置
        % 交換所選位置的派遣時間值
        temp_time = dispatch_times1(pos_dispatch(1));
        dispatch_times1(pos_dispatch(1)) = dispatch_times1(pos_dispatch(2));
        dispatch_times1(pos_dispatch(2)) = dispatch_times1(pos_dispatch(3));
        dispatch_times1(pos_dispatch(3)) = temp_time;
    end

    % 返回新的突變後的染色體和派遣時間
    Y = A1; % 返回突變後的染色體
    dispatch_times_new2 = dispatch_times1; % 返回突變後的派遣時間
    % 顯示變異後的派遣時間
    disp('變異後的派遣時間：');
    disp(dispatch_times_new2);
end
