------------------
export type InternalCase = {
    [any]: any
}

type MetaCase = {
    __call: (Case: Case, Index: any, ...any?) -> ...any,
    __add: (Case: Case, ...any) -> Case
}
------------------

export type Case = setmetatable<InternalCase, MetaCase>

local Cases: {[string]: Case} = {}

local function NewCase(Name: string, Options: InternalCase): Case

    local returnCase: Case = setmetatable(
        Options,
        {
            __call = function(Case: Case, Index: any, ...: any): ...any
                if not Case[Index] then
                    return nil
                end

                if ... then
                    return Case[Index](...)
                else
                    return Case[Index]
                end
            end,
            __add = function(mergeTo: Case, toMerge: Case): Case
                for Index,Key in pairs(toMerge) do
                    mergeTo[Index] = Key
                end
                return (mergeTo :: any) :: Case
            end
        }
    )

    Cases[Name] = returnCase
    return returnCase
end

return NewCase
