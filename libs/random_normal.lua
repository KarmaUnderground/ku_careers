--uses the polar form of the Box-Muller transformation to return one (or two) number with normal distribution (average=0 and variance=1)
local function internal_rand_normal()
    local x1, x2, w, y1, y2
    repeat 
        x1 = 2 * math.random() - 1
        x2 = 2 * math.random() - 1
        w = x1*x1+x2*x2
    until (w < 1)

    w = math.sqrt((-2*math.log(w))/w)
    y1 = x1*w
    y2 = x2*w
    return y1,y2
end

function rand_normal(min,max,variance,strict_min,strict_max)
    local average=(min+max)/2
    if variance==nil then variance=2.4 end --2.4 because it means that 98,36% from all values will be between min and max
    local escala=(max-average)/variance 
    local x=escala*internal_rand_normal()+average
    if strict_min~=nil then
        x=math.max(x,strict_min)
    end
    if strict_max~=nil then
        x=math.min(x,strict_max)
    end
    return(x)
end

--variance = 0.5 => 38,28% of all random values between min and max
--variance = 0.7 => 51,6% of all random values between min and max
--variance = 1.0 => 68,27% of all random values between min and max
--variance = 1.2 => 77% of all random values between min and max
--variance = 1.5 => 86,63% of all random values between min and max
--variance = 1.7 => 91,2% of all random values between min and max
--variance = 2.0 => 95,4% of all random values between min and max
--variance = 2.4 => 98,36% of all random values between min and max
--variance = 4.0 => 99,98% of all random values between min and max