--
-- GlobalCompany - FillTypeManager
--
-- @Interface: --
-- @Author: LS-Modcompany / kevink98
-- @Date: 07.08.2019
-- @Version: 1.1.0.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
--
-- 	v1.1.0.0 (07.08.2019):
-- 		- add reg for Giants-filltypes
--
-- 	v1.0.0.0 (01.01.2019):
-- 		- initial fs19 (kevink98)
--
-- Notes:
--
--
-- ToDo:
--
--

GC_FillTypeManager = {};
local GC_FillTypeManager_mt = Class(GC_FillTypeManager);

GC_FillTypeManager.debugIndex = g_company.debug:registerScriptName("GlobalCompany-GC_FillTypeManager");

function GC_FillTypeManager:new()
    local self = {};
	setmetatable(self, GC_FillTypeManager_mt);

    self.extendedFillTypes = {};
    self.extendedFillTypesById = {};
    self.extendedFillTypesByName = {};
    self.extendedFillTypesCategories = {};

    self.xmlFiles = {};

    g_company.addLoadable(self, self.load);

	self.debugData = g_company.debug:getDebugData(GC_FillTypeManager.debugIndex);

	return self;
end;

function GC_FillTypeManager:loadFromXML(modName, xmlFile)

    local key = "globalCompany.fillTypeManager";
    if not hasXMLProperty(xmlFile, key) then
        return;
    end;

    local filename = getXMLString(xmlFile, key .. "#filename");
    if filename == nil or filename == "" then
        return;
    end;

    local path = g_company.utils.createModPath(modName, filename);

    if not fileExists(path) then
        return;
    end;

    table.insert(self.xmlFiles, {path=path, modName=modName});
end

function GC_FillTypeManager:load()
    local newFilltype = false;
    for _,data  in pairs(self.xmlFiles) do
        local xmlFile = loadXMLFile("map", data.path);

        local i = 0
        while true do
            local xmlKey = string.format("map.fillTypes.fillType(%d)", i);
            if not hasXMLProperty(xmlFile, xmlKey) then
                break;
            end;

            local name = getXMLString(xmlFile, xmlKey .. "#name");
            local title = getXMLString(xmlFile, xmlKey .. "#title");
            local showOnPriceTable = getXMLBool(xmlFile, xmlKey .. "#showOnPriceTable");
            local pricePerLiter = getXMLFloat(xmlFile, xmlKey .. "#pricePerLiter");
            local massPerLiter = getXMLFloat(xmlFile, xmlKey .. ".physics#massPerLiter") / 1000;
            local maxPhysicalSurfaceAngle = getXMLInt(xmlFile, xmlKey .. ".physics#maxPhysicalSurfaceAngle");
            local hudOverlayFilename = getXMLString(xmlFile, xmlKey .. ".image#hud");
            local hudOverlayFilenameSmall = getXMLString(xmlFile, xmlKey .. ".image#hudSmall");
            local palletFilename = getXMLString(xmlFile, xmlKey .. ".pallet#filename");

            --local s,_ = palletFilename:find("$data");
            --if s == nil then
                --palletFilename = g_company.utils.createModPath(data.modName, palletFilename);
            --end;

            title = g_company.languageManager:getText(string.format("%s_%s", string.gsub(data.modName, "FS19_", ""), string.gsub(title, "$l10n_", "")));

            g_fillTypeManager:addFillType(name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudOverlayFilename, hudOverlayFilenameSmall, g_company.utils.createDirPath(data.modName), nil, {1,1,1}, palletFilename, false);
            newFilltype = true;
            i = i + 1;
        end;

        i = 0
        while true do
            local xmlKey = string.format("map.fillTypeCategories.fillTypeCategory(%d)", i);
            if not hasXMLProperty(xmlFile, xmlKey) then
                break;
            end;

            local name = getXMLString(xmlFile, xmlKey .. "#name");
            local fillTypes = getXMLString(xmlFile, xmlKey);
            local typesSplit = g_company.utils.splitString(fillTypes, " ");

            for _,type in pairs(typesSplit) do
                local categoryIndex = g_fillTypeManager.nameToCategoryIndex[name];
                g_fillTypeManager:addFillTypeToCategory(g_fillTypeManager:getFillTypeIndexByName(type), categoryIndex);
            end;
            i = i + 1;
        end;

        i = 0
        while true do
            local xmlKey = string.format("map.materialholders.materialholder(%d)", i);
            if not hasXMLProperty(xmlFile, xmlKey) then
                break;
            end;

            local matHolderFileName = getXMLString(xmlFile, xmlKey .. "#filename");
            if matHolderFileName ~= nil then
                loadI3DFile(g_company.utils.createModPath(data.modName, matHolderFileName));
            end;

            i = i + 1;
        end;

        i = 0
        while true do
            local xmlKey = string.format("map.extendedFillTypes.fillType(%d)", i)
            if not hasXMLProperty(xmlFile, xmlKey) then
                break
            end

            local name = getXMLString(xmlFile, xmlKey .. "#name")
            local title = getXMLString(xmlFile, xmlKey .. "#title")
            local palletFilename = getXMLString(xmlFile, xmlKey .. ".pallet#filename")
            local colorMat = getXMLString(xmlFile, xmlKey .. ".color#mat")
            --local s = string.format("%s_%s", string.gsub(data.modName, "FS19_", ""), string.gsub(title, "$l10n_", ""))
            title = g_company.languageManager:getText(title)

            self:addExtendedFillType(name, title, palletFilename, colorMat)
            i = i + 1;
        end

        i = 0
        while true do
            local xmlKey = string.format("map.extendedFillTypesCategories.extendedFillTypesCategory(%d)", i);
            if not hasXMLProperty(xmlFile, xmlKey) then
                break
            end

            local name = getXMLString(xmlFile, xmlKey .. "#name")
            local fillTypes = getXMLString(xmlFile, xmlKey .. "#fillTypes")

            self:addExtendedFillTypeCategory(name, g_company.utils.splitString(fillTypes, " "))
            i = i + 1
        end

        if hasXMLProperty(xmlFile, "map.extendedFillTypesMaterials") then
            self:loadExtendedFilltypeMaterials(xmlFile, "map.extendedFillTypesMaterials", data.modName)
        end



    end

    if newFilltype then
        g_currentMission.hud.fillLevelsDisplay:refreshFillTypes(g_fillTypeManager)
    end
end

function GC_FillTypeManager:getNextId()
    if self.fillTypeId == nil then
        self.fillTypeId = 0
    end;
    self.fillTypeId = self.fillTypeId + 1
    return self.fillTypeId
end

function GC_FillTypeManager:addExtendedFillType(name, title, palletFilename, colorMat)
    name = name:upper()

    if self.extendedFillTypesByName[name] ~= nil then
		g_company.debug:writeError(self.debugData, "Filltype %s already exist.", name)
        return
    end

    local newFilltype = {}
    newFilltype.name = name
    newFilltype.title = title
    newFilltype.palletFilename = palletFilename

    if colorMat ~= nil then
        newFilltype.colorMat = g_company.utils.splitString(colorMat, " ")
    end

    newFilltype.index = self:getNextId()

    self.extendedFillTypesByName[newFilltype.name] = newFilltype
    self.extendedFillTypesById[newFilltype.index] = newFilltype
end

function GC_FillTypeManager:addExtendedFillTypeCategory(name, fillTypes)
    name = name:upper()
    if self.extendedFillTypesCategories[name] == nil then
        self.extendedFillTypesCategories[name] = {}
    end

    for _,fillTypeName in pairs(fillTypes) do
        if self.extendedFillTypesByName[fillTypeName] == nil then
            g_company.debug:writeError(self.debugData, "Filltype %s not exist.", fillTypeName)
        end

        table.insert(self.extendedFillTypesCategories[name], fillType)
        self.extendedFillTypesByName[fillTypeName].category = name
    end
end

function GC_FillTypeManager:getExtendedFillTypeByName(name)
    return self.extendedFillTypesByName[name:upper()]
end

function GC_FillTypeManager:getExtendedFillTypeByIndex(index)
    return self.extendedFillTypesById[index]
end

function GC_FillTypeManager:getExtendedFillTypeIndexByName(name)
    if self.extendedFillTypesByName[name:upper()] ~= nil then
        return self.extendedFillTypesByName[name:upper()].index
    end
end

function GC_FillTypeManager:getExtendedFillTypeNameByIndex(index)
    if self.extendedFillTypesById[index] ~= nil then
        return self.extendedFillTypesById[index].name
    end
end


function GC_FillTypeManager:getExtendedFillTypeById(id)
    return self.extendedFillTypesById[id]
end

function GC_FillTypeManager:getExtendedFillTypeByCategorie(name)
    return self.extendedFillTypesCategories[name]
end

function GC_FillTypeManager:getIsExtendedFillTypeIsInCategorie(filltypename, categorie)
    return self.extendedFillTypesByName[filltypename].category == categorie
end

function GC_FillTypeManager:loadExtendedFilltypeMaterials(xmlFile, xmlKey, modName)
    local materialPath = getXMLString(xmlFile, xmlKey .. "#materialHolder");
    local materials = GC_i3dLoader:loadMaterials(materialPath, g_company.utils.createDirPath(modName), xmlFile, xmlKey)

    for name, material in pairs(materials) do
        if self.extendedFillTypesByName[name:upper()] ~= nil then
            self.extendedFillTypesByName[name:upper()].material = material
        else
            print(string.format("GC_FillTypeManager invalid filltype %s", name))
        end
    end
end



--[[

function GC_FillTypeManager:registerFillType(name, lang)
    if self.fillTypesByName[name] ~= nil then
        --debug
        return;
    end;

    local newFillType = {};
    newFillType.id = self:getNextId();
    newFillType.name = name;
    newFillType.langName = g_company.languageManager:getText(lang);

    self.fillTypesById[newFillType.id] = newFillType;
    self.fillTypesByName[name] = newFillType;
    table.insert(self.fillTypes, newFillType);
    return newFillType.id;
end;

function GC_FillTypeManager:loadFromXML(xmlFile)
    local insertFillTypes = {};
    local i = 0;
    while true do
        local key = string.format("globalCompany.registerFillTypes.fillType(%d)", i);
        if not hasXMLProperty(xmlFile, key) then
            break;
        end;

        local name = getXMLString(xmlFile, key .. "#name");
        local langName = getXMLString(xmlFile, key .. "#langName");
        table.insert(insertFillTypes, self:registerFillType(name, langName));
        i = i + 1;
    end;
    return insertFillTypes;
end

function GC_FillTypeManager:readFillTypesFromXML(xmlFile, xmlKey)
    local fillTypes = {};
    local i = 0;
    while true do
        local key = string.format("%s.fillTypes.fillType(%d)", xmlKey, i);
        if not hasXMLProperty(xmlFile, key) then
            break;
        end;

        local name = getXMLString(xmlFile, key .. "#name");
        table.insert(fillTypes, self:getFillTypeByName(name));
        i = i + 1;
    end;
    return fillTypes;
end

function GC_FillTypeManager:getFillTypeLangNameById(id)
    if self.fillTypesById[id] ~= nil then
        return self.fillTypesById[id].langName;
    else
        --debug
        return "Not found"
    end;
end;

function GC_FillTypeManager:getFillTypeNameById(id)
    if self.fillTypesById[id] ~= nil then
        return self.fillTypesById[id].name;
    else
        --debug
        return "Not found"
    end;
end;

function GC_FillTypeManager:getFillTypeByName(name)
    if self.fillTypesByName[name] ~= nil then
        return self.fillTypesByName[name];
    else
        --debug
        return "Not found"
    end;
end;

function GC_FillTypeManager:getFillTypeIdByName(name)
    if self.fillTypesByName[name] ~= nil then
        return self.fillTypesByName[name].id;
    else
        --debug
        return "Not found"
    end;
end;
]]--