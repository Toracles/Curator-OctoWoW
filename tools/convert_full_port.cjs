const fs = require("node:fs");
const path = require("node:path");
const parser = require("../.port-runtime/package");

const staging = path.resolve(__dirname, "../full-port-work/Curator");
const tocFile = path.join(staging, "Curator.toc");
const toc = fs.readFileSync(tocFile, "utf8");
const files = toc.split(/\r?\n/).filter(line => line.endsWith(".lua") && line !== "OctoCompat.lua");
const report = [];

function convert(source, file) {
    const ast = parser.parse(source, { luaVersion: "5.1", ranges: true, scope: true });
    const edits = [];
    const dependencies = new Set();
    const metrics = { lengths: 0, varargs: 0, remainder: 0 };
    const edit = (range, value) => edits.push({ range, value, order: edits.length });
    for (const statement of ast.body) {
        if (statement.type === "LocalStatement" && statement.init.length === 1 &&
                statement.init[0].type === "VarargLiteral" && statement.variables.length === 2) {
            edit(statement.init[0].range, '"Curator", CuratorOctoFull');
        }
    }

    // Collapse chunk-local UI constants into one captured table on Lua 5.0.
    const constants = new Set();
    if (/^UI[\\/](Card|Contract|Profile|Boosters|Inns)\.lua$/.test(file)) {
        const counts = new Map();
        function countBindings(node) {
            if (!node || typeof node !== "object") return;
            if (node.type === "LocalStatement" || node.type === "ForGenericStatement") {
                for (const variable of node.variables)
                    counts.set(variable.name, (counts.get(variable.name) || 0) + 1);
            }
            if (node.type === "ForNumericStatement")
                counts.set(node.variable.name, (counts.get(node.variable.name) || 0) + 1);
            if (node.type === "FunctionDeclaration") {
                for (const parameter of [...node.parameters, node.isLocal ? node.identifier : null])
                    if (parameter?.name) counts.set(parameter.name, (counts.get(parameter.name) || 0) + 1);
            }
            for (const value of Object.values(node))
                if (Array.isArray(value)) value.forEach(countBindings);
                else countBindings(value);
        }
        countBindings(ast);
        for (const node of ast.body) {
            if (node.type !== "LocalStatement" || !node.init.length ||
                    !node.variables.every(variable => /^[A-Z][A-Z_0-9]{2,}$/.test(variable.name)
                        && counts.get(variable.name) === 1)) continue;
            edit([node.range[0], node.variables[0].range[0]], "");
            for (const variable of node.variables) constants.add(variable.name);
        }
    }

    function visit(node, parent, context) {
        if (!node || typeof node !== "object") return;
        if (node.type === "FunctionDeclaration") context = node;
        if (node.type === "ForGenericStatement" || node.type === "ForNumericStatement") {
            const variables = node.variables || [node.variable];
            const names = variables.map(variable => variable.name);
            function captures(value) {
                if (!value || typeof value !== "object") return false;
                if (value.type === "FunctionDeclaration") {
                    const body = source.slice(...value.range);
                    return names.some(name => body.includes(name));
                }
                return Object.values(value).some(child =>
                    Array.isArray(child) ? child.some(captures) : captures(child));
            }
            if (node.body.length && node.body.some(captures)) {
                const list = names.join(", ");
                edit([node.body[0].range[0], node.body[0].range[0]], "local " + list + " = " + list + "; ");
            }
        }
        if (node.type === "MemberExpression" && node.base.name === "math" && node.identifier.name === "huge")
            edit(node.range, "CuratorOctoFull.Huge");
        if (node.type === "MemberExpression" && node.indexer === "." && node.identifier.name === "HookScript")
            edit(node.range, "CuratorOctoFull.HookScript");
        if (node.type === "NumericLiteral" && /^0x/i.test(node.raw))
            edit(node.range, String(node.value));
        if (node.type === "Identifier" && node.isLocal && constants.has(node.name) &&
                !(parent.type === "MemberExpression" && parent.identifier === node) &&
                !(parent.type === "TableKeyString" && parent.key === node))
            edit(node.range, "octoConstants." + node.name);
        if (node.type === "Identifier" && /^C_[A-Z]/.test(node.name)) dependencies.add(node.name);
        if (node.type === "Identifier" && node.name === "C_ChatInfo" && !(parent.type === "MemberExpression" && parent.identifier === node))
            edit(node.range, "CuratorOctoFull.Chat");
        if (node.type === "Identifier" && node.name === "C_Timer" && !(parent.type === "MemberExpression" && parent.identifier === node))
            edit(node.range, "CuratorOctoFull.Timer");
        if (node.type === "Identifier" && (node.name === "CuratorDB" || node.name === "CuratorExport"))
            edit(node.range, node.name.replace("Curator", "CuratorOctoFull"));
        if (node.type === "StringLiteral") {
            const raw = source.slice(...node.range);
            if (raw === '"BackdropTemplate"' && parent.type === "CallExpression" &&
                    parent.base.name === "CreateFrame")
                edit(node.range, "CuratorOctoFull.BackdropTemplate()");
            if (raw === '"CuratorDB"' || raw === '"CuratorExport"')
                edit(node.range, raw.replace("Curator", "CuratorOctoFull"));
        }
        if (node.type === "CallExpression" && node.base.type === "MemberExpression" &&
                node.base.indexer === "." && node.base.base.name === "string" && node.base.identifier.name === "byte")
            edit(node.base.range, "CuratorOctoFull.Byte");
        if (node.type === "CallExpression" && node.base.type === "MemberExpression" &&
                node.base.indexer === "." && node.base.base.name === "table" && ["insert","remove"].includes(node.base.identifier.name))
            edit(node.base.range, "CuratorOctoFull." + (node.base.identifier.name === "insert" ? "Insert" : "Remove"));
        if (node.type === "CallExpression" && node.base.type === "Identifier" && ["select", "GetServerTime", "wipe"].includes(node.base.name))
            edit(node.base.range, "CuratorOctoFull." + ({select:"Select",GetServerTime:"ServerTime",wipe:"Wipe"})[node.base.name]);
        if (node.type === "CallExpression" && node.base.type === "MemberExpression" &&
                node.base.indexer === ":" && ["SetScript", "SetSize", "SetColorTexture", "SetShown", "SetClipsChildren",
                 "CreateMaskTexture", "AddMaskTexture", "RemoveMaskTexture", "HookScript", "GetSize", "GetRect", "GetStringHeight", "GetEffectiveScale",
                 "SetMotionScriptsWhileDisabled", "SetClampedToScreen", "SetAutoFocus", "SetDesaturated", "SetRotation", "GetRotation", "SetEnabled", "SetWordWrap", "SetMaxLines",
                 "SetPortraitZoom", "SetCamDistanceScale", "SetParticlesEnabled", "SetPaused", "SetLight",
                 "byte", "char", "find", "format", "gmatch", "gsub", "len", "lower", "match", "rep", "sub", "upper"].includes(node.base.identifier.name)) {
            // Keep script signatures in the upstream code; pass legacy event globals through at the boundary.
            const base = node.base.base;
            const method = node.base.identifier.name;
            const variants = { SetColorTexture:"ColorTexture", gmatch:"Gmatch", match:"Match", byte:"Byte" };
            const prefix = /^[a-z]/.test(method) && !variants[method] ? "string." : "CuratorOctoFull.";
            edit([node.range[0], node.range[0]], prefix + (variants[method] || method) + "(");
            const separator = source.lastIndexOf(":", node.base.identifier.range[0]);
            if (node.arguments.length) {
                const open = source.indexOf("(", node.base.identifier.range[1]);
                edit([separator, open + 1], ", ");
            } else {
                edit([separator, node.range[1]], ")");
            }
        }
        if (node.type === "VarargLiteral" && context && !context.parameters.includes(node)) {
            // Lua 5.0 exposes function arguments in the implicit arg table.
            edit(node.range, "unpack(arg, 1, arg.n)");
            metrics.varargs++;
        }
        if (node.type === "UnaryExpression" && node.operator === "#") {
            edit([node.range[0], node.range[0] + 1], "CuratorOctoFull.Length(");
            edit([node.range[1], node.range[1]], ")");
            metrics.lengths++;
        }
        if (node.type === "BinaryExpression" && node.operator === "%") {
            const inner = source.slice(node.left.range[1], node.right.range[0]);
            const operator = inner.indexOf("%");
            edit([node.range[0], node.range[0]], "CuratorOctoFull.Mod(");
            edit([node.left.range[1] + operator, node.left.range[1] + operator + 1], ",");
            edit([node.range[1], node.range[1]], ")");
            metrics.remainder++;
        }
        // Include child expressions inside converted operators, using original source ranges.
        for (const [key, value] of Object.entries(node)) {
            if (key === "range") continue;
            if (Array.isArray(value)) value.forEach(child => visit(child,node,context));
            else visit(value,node,context);
        }
    }
    visit(ast, null, null);
    const unique = edits.filter((edit, index) => edit.range[0] === edit.range[1] ||
        edits.findIndex(other => other.range[0] === edit.range[0] && other.range[1] === edit.range[1]) === index);
    unique.sort((a,b) => b.range[0] - a.range[0] || b.range[1] - a.range[1] || b.order - a.order);
    let result = source;
    for (const {range, value} of unique) result = result.slice(0, range[0]) + value + result.slice(range[1]);
    // Lua 5.0 replacement strings require an explicit capture instead of %0.
    if (file === "Tavern.lua" || file === "Pvp.lua") {
        result = result.replace(/string\.gsub\(fmt, "(\[[^"\r\n]+\])", "%%%0"\)/g,
            (_, pattern) => 'string.gsub(fmt, "(' + pattern + ')", "%%%1")');
    }
    if (file === "Beta.lua") result = result.replace("return not self:ForeverClient()", "return not CuratorOctoFull.IsOctoClient() and not self:ForeverClient()");
    if (file === "UI\\Card.lua" || file === "UI/Card.lua") {
        result = result.replace('CuratorOctoFull.SetScript(m, "OnModelLoaded", function(self)',
            'm.hasLoadScript = CuratorOctoFull.SetScript(m, "OnModelLoaded", function(self)');
        result = result.replace("m.display = (not por or self.live3D) and card.display or nil",
            "m.display = (not por or self.live3D) and card.display and card.display > 0 and card.display or nil");
        result = result.replace("elseif m.display then\n\t\tm:ClearModel()\n\t\tm:SetDisplayInfo(m.display)\n\t\tApplyModelLook(m)\n\t\tm:SetAnimation(0)",
            `elseif m.display and m.SetDisplayInfo then
		m:ClearModel()
		m:SetDisplayInfo(m.display)
		ApplyModelLook(m)
		if m.SetAnimation then m:SetAnimation(0) end
		if not m.hasLoadScript then m.loaded = true end`);
        result = result.replace("if ok and has then\n\t\t\tm:SetAnimation(anim)", "if ok and has and m.SetAnimation then\n\t\t\tm:SetAnimation(anim)");
    }
    if (file === "UI\\Cinematic.lua" || file === "UI/Cinematic.lua")
        result = result.replace("local f = self.frame\n\tns.CancelOwner(self)\n\tself:HideCards()", "local f = self.frame\n\tif not (card.display and card.display > 0 and (f.scene or (f.model.SetDisplayInfo and f.model.SetAnimation))) then return false end\n\tns.CancelOwner(self)\n\tself:HideCards()");
    if (file === "UI\\Hud.lua" || file === "UI/Hud.lua") {
        result = result.replace("local enable = b.SetEnabled", `local enable = b.SetEnabled or function(button, on)
        if on then button:Enable() else button:Disable() end
    end`);
    }
    if (constants.size) result = "local octoConstants = {}\n" + result;
    try { parser.parse(result, {luaVersion:"5.1"}); } catch (error) {
        throw new Error(file + ": " + error.message + "\n" + result.split("\n")[error.line-1]);
    }
    report.push({ file, ...metrics, dependencies:[...dependencies].sort() });
    return result;
}

for (const relative of files) {
    const file = path.join(staging, relative.replaceAll("\\","/"));
    fs.writeFileSync(file, convert(fs.readFileSync(file,"utf8"),relative));
}
fs.copyFileSync(path.resolve(__dirname,"../full-port/OctoCompat.lua"),path.join(staging,"OctoCompat.lua"));
fs.writeFileSync(tocFile,toc.replace(/^(Locale\.lua)/m,"OctoCompat.lua\n$1"));
fs.writeFileSync(path.join(staging,"../conversion.json"),JSON.stringify(report,null,2));
console.log("Converted modules:",report.length);
for (const key of ["lengths","varargs","remainder"])
    console.log(key,report.reduce((sum,row)=>sum+row[key],0));
console.log("Modern API namespaces:",new Set(report.flatMap(row=>row.dependencies)).size);
